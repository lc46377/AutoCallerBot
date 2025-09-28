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
  bool typing = false; // show "assistant is typing"

  bool get hasActiveCall => callId != null;
  bool get isCollecting => _sessionId != null && !hasActiveCall;

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

  Future<void> send() async {
    final input = inputController.text.trim();
    if (input.isEmpty || isBusy) return;

    // push user bubble
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

        // assistant reply
        if (start.callId != null && start.callId!.isNotEmpty) {
          callId = start.callId;
          messages.add(ChatMessage(
              'Calling the company now… (Call ID: $callId)',
              fromUser: false));
        } else if (start.question.isNotEmpty) {
          messages.add(ChatMessage(start.question, fromUser: false));
        }
      } else {
        final IntakeReplyResponse rep =
            await _api.intakeReply(_sessionId!, input);

        if (rep.done) {
          if (rep.callId != null && rep.callId!.isNotEmpty) {
            callId = rep.callId;
            final text = rep.message?.isNotEmpty == true
                ? rep.message!
                : 'Calling the company now… (Call ID: $callId)';
            messages.add(ChatMessage(text, fromUser: false));
          } else {
            messages.add(ChatMessage(rep.message ?? 'Done.', fromUser: false));
          }
        } else {
          // still collecting info
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
    try {
      await _api.hangupBySession(_sessionId!);
      callId = null;
      messages.add(ChatMessage('Call ended.', fromUser: false));
      // allow starting a brand-new flow without leaving the screen
      _sessionId = null;
      typing = false;
      notifyListeners();
      _scrollToEnd();
    } catch (e) {
      messages.add(ChatMessage('Could not end the call. You can try again.',
          fromUser: false));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
