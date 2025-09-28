import 'package:flutter/material.dart';

import '../../models/call_log.dart';

class CallLogCard extends StatefulWidget {
  const CallLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  final CallLog log;
  final VoidCallback? onTap;

  @override
  State<CallLogCard> createState() => _CallLogCardState();
}

class _CallLogCardState extends State<CallLogCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final scheme = Theme.of(context).colorScheme;
    final timeString = TimeOfDay.fromDateTime(log.time).format(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (log.success ? scheme.primary : scheme.error)
                .withOpacity(0.12),
            child: Icon(
              log.success ? Icons.check_rounded : Icons.close_rounded,
              color: log.success ? scheme.primary : scheme.error,
            ),
          ),
          title: Text(log.title),
          subtitle: Text(log.subtitle),
          trailing: Text(
            timeString,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }
}


