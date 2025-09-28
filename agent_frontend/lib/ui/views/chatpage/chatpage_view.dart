import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'chatpage_viewmodel.dart';
import '../../common/app_theme.dart';

class ChatpageView extends StackedView<ChatpageViewModel> {
  const ChatpageView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ChatpageViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Task')),
      body: Container(
        decoration: gradientBg(context),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: viewModel.scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: viewModel.messages.length,
                itemBuilder: (context, index) {
                  final msg = viewModel.messages[index];
                  final align = msg.fromUser ? Alignment.centerRight : Alignment.centerLeft;
                  final bubbleColor = msg.fromUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface;
                  final textColor = msg.fromUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface;
                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(msg.fromUser ? 16 : 4),
                          bottomRight: Radius.circular(msg.fromUser ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (viewModel.hasActiveCall)
              Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Icon(Icons.phone_in_talk,
                          color: Theme.of(context).colorScheme.primary),
                      const Text('Calling the company now…'),
                      TextButton.icon(
                        onPressed: viewModel.hangup,
                        icon: const Icon(Icons.call_end),
                        label: const Text('Hang up'),
                      ),
                    ],
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: viewModel.inputController,
                        enabled: !viewModel.isBusy,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => viewModel.send(),
                        decoration: const InputDecoration(
                          hintText: 'Describe what you need…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: viewModel.isBusy ? null : viewModel.send,
                      child: viewModel.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  ChatpageViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      ChatpageViewModel();
}
