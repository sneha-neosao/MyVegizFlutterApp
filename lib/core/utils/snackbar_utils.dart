import 'dart:async';
import 'package:flutter/material.dart';

class SnackbarUtils {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void showSuccessSnackbar(
    BuildContext context, 
    String message, {
    String? actionLabel, 
    VoidCallback? onActionPressed,
  }) {
    _showPopup(
      context, 
      message, 
      isError: false, 
      actionLabel: actionLabel, 
      onActionPressed: onActionPressed,
    );
  }

  static void showErrorSnackbar(
    BuildContext context, 
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showPopup(
      context, 
      message, 
      isError: true, 
      actionLabel: actionLabel, 
      onActionPressed: onActionPressed,
    );
  }

  static void _showPopup(
    BuildContext context, 
    String message, {
    required bool isError,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Clear any active snackbar / toast
    _timer?.cancel();
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (_) {}
      _currentEntry = null;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback to standard ScaffoldMessenger if overlay is not available
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
          ),
          backgroundColor: isError ? Colors.grey.shade800 : const Color(0xFFFC8019),
          duration: const Duration(seconds: 2),
          action: actionLabel != null && onActionPressed != null
              ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onActionPressed)
              : null,
        ),
      );
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        isError: isError,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        onDismiss: () {
          _timer?.cancel();
          if (_currentEntry == entry) {
            try {
              entry.remove();
            } catch (_) {}
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(seconds: 2, milliseconds: 400), () {
      if (_currentEntry == entry) {
        try {
          entry.remove();
        } catch (_) {}
        _currentEntry = null;
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isError,
    this.actionLabel,
    this.onActionPressed,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Start smooth fade-out before removal
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomMargin = (bottomInset > 0 ? bottomInset : bottomPadding) + 24.0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomMargin,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isError
                    ? Colors.grey.shade800
                    : const Color(0xFFFC8019),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        widget.onActionPressed!();
                        widget.onDismiss();
                      },
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
