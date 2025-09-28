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
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.bolt)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Assistant", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: viewModel.hasActiveCall
                      ? _StatusPill(
                          key: const ValueKey('oncall'),
                          icon: Icons.call_end_rounded,
                          color: cs.errorContainer,
                          label: "On call",
                          onTap: viewModel.hangup,
                        )
                      : _StatusPill(
                          key: const ValueKey('ready'),
                          icon: Icons.circle,
                          color: cs.secondaryContainer,
                          label: "Ready",
                        ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "End call",
            onPressed: viewModel.hasActiveCall ? viewModel.hangup : null,
            icon: const Icon(Icons.call_end_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              cs.surfaceVariant.withOpacity(.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: viewModel.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: viewModel.messages.length + (viewModel.isCollecting ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == viewModel.messages.length && viewModel.isCollecting) {
                      return const _TypingBubble();
                    }
                    final msg = viewModel.messages[index];
                    final isUser = msg.fromUser;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isUser ? cs.primaryContainer : cs.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isUser ? 18 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 18),
                            ),
                            border: Border.all(color: cs.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withOpacity(.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            child: Text(
                              msg.text,
                              style: textTheme.bodyLarge?.copyWith(
                                color: isUser ? cs.onPrimaryContainer : cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              _Composer(
                controller: viewModel.inputController,
                busy: viewModel.isBusy,
                onSend: viewModel.send,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  ChatpageViewModel viewModelBuilder(BuildContext context) => ChatpageViewModel();
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.busy, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Type a message...",
                prefixIcon: const Icon(Icons.chat_bubble_outline),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            width: 52,
            child: FloatingActionButton(
              onPressed: busy ? null : onSend,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(),
            SizedBox(width: 4),
            _Dot(delay: 100),
            SizedBox(width: 4),
            _Dot(delay: 200),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({this.delay = 0});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = ((_controller.value * 1000 + widget.delay) % 900) / 900.0;
        final scale = 0.6 + (t < 0.5 ? t : 1 - t) * 0.8;
        return Transform.scale(
          scale: scale,
          child: const CircleAvatar(radius: 3),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _StatusPill({super.key, required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}