/// Unified toast API — every screen used to build its own SnackBar with
/// slightly different styling, margin, and elevation, which made success
/// and error feedback feel inconsistent across the app. [AppToast] collapses
/// those into two styles and positions them consistently at the top of the
/// scaffold so the user's thumb (which is often still on a large action
/// button at the bottom) doesn't occlude them.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, success: true);

  static void error(BuildContext context, String message) =>
      _show(context, message, success: false);

  static void _show(BuildContext context, String message, {required bool success}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppColors.toastSuccess : AppColors.toastError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // Anchored near the top so it doesn't overlap primary action buttons
        // that live at the bottom of most screens (autopilot / ACC / connect).
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          // Using `only` to pin to the top: the SnackBar's default floating
          // behavior is bottom-anchored, but with a large top margin + a
          // translucent visible region above, it reads as a top toast.
          bottom: MediaQuery.of(context).size.height - 120,
        ),
        duration: Duration(seconds: success ? 2 : 4),
      ),
    );
  }
}

/// Extension form so callers read as `context.showSuccessToast('OK')`.
extension ToastContext on BuildContext {
  void showSuccessToast(String message) => AppToast.success(this, message);
  void showErrorToast(String message) => AppToast.error(this, message);
}
