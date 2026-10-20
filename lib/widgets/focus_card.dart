import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// The core TV primitive: a D-pad focusable surface that scales up, glows,
/// scrolls itself into view and fires [onSelect] on OK / Enter / tap.
class FocusCard extends StatefulWidget {
  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback onSelect;
  final VoidCallback? onLongSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final double focusScale;
  final BorderRadius radius;
  final bool glow;
  final ValueChanged<bool>? onFocusChange;

  const FocusCard({
    super.key,
    required this.builder,
    required this.onSelect,
    this.onLongSelect,
    this.autofocus = false,
    this.focusNode,
    this.focusScale = 1.08,
    this.radius = const BorderRadius.all(Radius.circular(18)),
    this.glow = true,
    this.onFocusChange,
  });

  @override
  State<FocusCard> createState() => _FocusCardState();
}

class _FocusCardState extends State<FocusCard> {
  bool _focused = false;
  bool _hovered = false;

  bool get _active => _focused || _hovered;

  static final _selectKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
  };

  void _handleFocus(bool f) {
    setState(() => _focused = f);
    widget.onFocusChange?.call(f);
    if (f) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocus,
      onKeyEvent: (node, event) {
        if (!_selectKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
        if (event is KeyDownEvent) widget.onSelect();
        if (event is KeyRepeatEvent && widget.onLongSelect != null) {
          widget.onLongSelect!();
        }
        return KeyEventResult.handled;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
          onLongPress: widget.onLongSelect,
          child: AnimatedScale(
            scale: active ? widget.focusScale : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                borderRadius: widget.radius,
                boxShadow: active && widget.glow
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.45),
                          blurRadius: 36,
                          spreadRadius: -2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.2),
                          blurRadius: 18,
                          spreadRadius: -4,
                          offset: const Offset(0, -2),
                        ),
                      ]
                    : const [],
              ),
              child: widget.builder(context, active),
            ),
          ),
        ),
      ),
    );
  }
}
