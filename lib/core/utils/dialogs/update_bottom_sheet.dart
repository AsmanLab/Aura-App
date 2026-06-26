import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';

Future<void> showUpdateBottomSheet(
  BuildContext context, {
  required String message,
  required String updateUrl,
  required bool isForced,
  required VoidCallback onSnooze,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: !isForced,
    enableDrag: !isForced,
    backgroundColor: Colors.transparent,
    builder: (_) => _UpdateSheet(
      message: message,
      updateUrl: updateUrl,
      isForced: isForced,
      onSnooze: onSnooze,
    ),
  );
}

class _UpdateSheet extends StatelessWidget {
  final String message;
  final String updateUrl;
  final bool isForced;
  final VoidCallback onSnooze;

  const _UpdateSheet({
    required this.message,
    required this.updateUrl,
    required this.isForced,
    required this.onSnooze,
  });

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the update link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.rLg),
        ),
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPad,
        AppSpacing.s3,
        AppSpacing.screenPad,
        AppSpacing.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle (hidden for force update)
          if (!isForced)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(height: AppSpacing.s5),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.aura(c),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),

          // Title
          Text(
            isForced ? 'Update required' : 'New version available',
            style: AppType.h2(c),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),

          // Message
          Text(
            message,
            style: AppType.bodyDim(c),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s6),

          // Update button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _openUrl(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  gradient: AppGradients.aura(c),
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Update now',
                  style: AppType.bodyStrong(c).copyWith(color: Colors.white),
                ),
              ),
            ),
          ),

          // Later button (soft update only)
          if (!isForced) ...[
            const SizedBox(height: AppSpacing.s3),
            GestureDetector(
              onTap: () {
                onSnooze();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Text(
                  'Later',
                  style: AppType.bodyStrong(c).copyWith(color: c.textDim),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
