import 'package:flutter/material.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';

enum _SnackbarType { success, error, info, warning }

/// App-wide custom snackbars. Usage:
///   AppSnackbar.success(context, 'Points awarded!');
///   AppSnackbar.error(context, 'Something went wrong.');
///   AppSnackbar.info(context, 'Available Mon–Fri 11:00–13:00.');
///   AppSnackbar.warning(context, 'Daily limit almost reached.');
class AppSnackbar {
  AppSnackbar._();

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) =>
      _show(context, message, _SnackbarType.success,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) =>
      _show(context, message, _SnackbarType.error,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) =>
      _show(context, message, _SnackbarType.info,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) =>
      _show(context, message, _SnackbarType.warning,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  static void _show(
    BuildContext context,
    String message,
    _SnackbarType type, {
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _SnackbarContent(
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenPad,
            0,
            AppSpacing.screenPad,
            AppSpacing.s5,
          ),
          padding: EdgeInsets.zero,
          duration: duration,
        ),
      );
  }
}

class _SnackbarContent extends StatelessWidget {
  final String message;
  final _SnackbarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackbarContent({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    final (IconData icon, Color accent) = switch (type) {
      _SnackbarType.success => (Icons.check_circle_rounded, c.success),
      _SnackbarType.error   => (Icons.error_rounded, c.heart),
      _SnackbarType.info    => (Icons.info_rounded, c.accentSolid),
      _SnackbarType.warning => (Icons.warning_rounded, const Color(0xFFF59E0B)),
    };

    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(AppSpacing.rSm),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(width: 4, color: accent),
            // Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              child: Icon(icon, color: accent, size: 20),
            ),
            // Message
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Text(message, style: AppType.body(c)),
              ),
            ),
            // Optional action
            if (actionLabel != null) ...[
              const SizedBox(width: AppSpacing.s2),
              GestureDetector(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s4,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppType.bodyStrong(c)
                        .copyWith(color: c.accentSolid),
                  ),
                ),
              ),
            ],
            // Dismiss
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: AppSpacing.s4,
                ),
                child: Icon(Icons.close, size: 16, color: c.textFaint),
              ),
            ),
            const SizedBox(width: AppSpacing.s1),
          ],
        ),
      ),
    );
  }
}
