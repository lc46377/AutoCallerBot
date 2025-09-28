// lib/ui/views/chatpage/chatpage_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../services/api_service.dart';
import '../../../models/intake.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime ts;
  ChatMessage(this.text, {required this.fromUser, DateTime? ts})
      : ts = ts ?? DateTime.now();
}

class ChatpageViewModel extends BaseViewModel {
  final _api = locator<ApiService>();

  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<ChatMessage> messages = [];
  String? _sessionId;
  String? callId;
  bool typing = false;

  Timer? _pollTimer;

  bool get hasActiveCall => callId != null;

  bool get isCollecting =>
      _sessionId != null && !hasActiveCall && !typing && !isBusy;

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (_sessionId == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final events = await _api.pollEvents(_sessionId!);
        if (events.isEmpty) return;
        for (final e in events) {
          final type = e['type']?.toString() ?? '';
          final text = e['text']?.toString() ?? '';
          if (text.isEmpty) continue;

          // Show all events as assistant bubbles
          messages.add(ChatMessage(text, fromUser: false));

          // If server says call ended, clear local flag
          if (type == 'status' && text.toLowerCase().contains('call ended')) {
            callId = null;
          }
        }
        notifyListeners();
        _scrollToEnd();
      } catch (_) {
        // ignore polling errors
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> send() async {
    final input = inputController.text.trim();
    if (input.isEmpty || isBusy) return;

    messages.add(ChatMessage(input, fromUser: true));
    inputController.clear();
    notifyListeners();
    _scrollToEnd();

    setBusy(true);
    typing = true;
    notifyListeners();

    try {
      if (_sessionId == null) {
        final IntakeStartResponse start = await _api.intakeStart(input);
        _sessionId = start.sessionId;

        if (start.callId != null && start.callId!.isNotEmpty) {
          callId = start.callId;
          messages.add(ChatMessage(
              'Calling the company now… (Call ID: $callId)',
              fromUser: false));
          _startPolling(); // start listening for summary/status
        } else if (start.question.isNotEmpty) {
          messages.add(ChatMessage(start.question, fromUser: false));
        }
      } else {
        final rep = await _api.intakeReply(_sessionId!, input);

        if (rep.done) {
          if (rep.callId != null && rep.callId!.isNotEmpty) {
            callId = rep.callId;
            final text = rep.message?.isNotEmpty == true
                ? rep.message!
                : 'Calling the company now… (Call ID: $callId)';
            messages.add(ChatMessage(text, fromUser: false));
            _startPolling(); // start listening for summary/status
          } else {
            messages.add(ChatMessage(rep.message ?? 'Done.', fromUser: false));
          }
        } else {
          messages.add(ChatMessage(
              rep.question ?? 'Please provide the remaining details.',
              fromUser: false));
        }
      }
    } catch (e) {
      messages.add(ChatMessage('Sorry, something went wrong. Please try again.',
          fromUser: false));
    } finally {
      typing = false;
      setBusy(false);
      notifyListeners();
      _scrollToEnd();
    }
  }

  Future<void> hangup() async {
    if (_sessionId == null) return;

    bool apiSuccess = false;

    try {
      await _api.hangupBySession(_sessionId!);
      apiSuccess = true;
    } catch (e) {
      messages.add(ChatMessage('Could not end the call. You can try again.',
          fromUser: false));
    } finally {
      callId = null;

      final successMessage =
          apiSuccess ? 'Call ended.' : 'Call ended, summary retrieving.';

      messages.add(ChatMessage(successMessage, fromUser: false));
      _stopPolling();
      notifyListeners();
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    _stopPolling();
    super.dispose();
  }
}
