import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum ToastType { success, error, info }

class ToastWidget {
  static OverlayEntry? _currentToast;

  static void show(BuildContext context, String message, ToastType type) {
    _currentToast?.remove();

    Color bgColor;
    switch (type) {
      case ToastType.success:
        bgColor = AppColors.green.withOpacity(0.95);
        break;
      case ToastType.error:
        bgColor = AppColors.red.withOpacity(0.95);
        break;
      case ToastType.info:
        bgColor = AppColors.blue.withOpacity(0.95);
        break;
    }

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        bgColor: bgColor,
        onDismiss: () {
          _currentToast?.remove();
          _currentToast = null;
        },
      ),
    );

    _currentToast = entry;
    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final Color bgColor;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.bgColor,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 40,
      right: 40,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.bgColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}