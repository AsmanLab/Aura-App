import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/category_chip.dart';
import '../bloc/award_cubit.dart';

class AwardPage extends StatelessWidget {
  const AwardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: BlocConsumer<AwardCubit, AwardState>(
          listenWhen: (p, n) =>
              (!p.submitted && n.submitted) ||
              (p.error != n.error && n.error != null),
          listener: (context, state) async {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!), backgroundColor: c.heart),
              );
              return;
            }
            HapticFeedback.lightImpact();
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => _SuccessDialog(points: state.points),
            );
            if (context.mounted) context.pop();
          },
          builder: (context, state) {
            final cubit = context.read<AwardCubit>();
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!state.canAward) {
              return _MentorsOnlyView(onClose: () => context.pop());
            }
            return Column(
              children: [
                // header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.close, color: c.text),
                      ),
                      Expanded(
                        child: Text(
                          'Award Aura',
                          textAlign: TextAlign.center,
                          style: AppType.h3(c),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // step bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPad,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              gradient: i <= state.step
                                  ? LinearGradient(
                                      colors: [c.accent1, c.accent2])
                                  : null,
                              color: i <= state.step ? null : c.surface3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppDurations.med,
                    child: _StepBody(
                      key: ValueKey(state.step),
                      state: state,
                      cubit: cubit,
                    ),
                  ),
                ),
                // footer
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPad),
                  child: Row(
                    children: [
                      if (state.step > 0)
                        TextButton(
                          onPressed: cubit.back,
                          child: Text('Back', style: AppType.bodyStrong(c)),
                        ),
                      const Spacer(),
                      if (state.step == 3)
                        _AwardButton(state: state, cubit: cubit)
                      else
                        _PrimaryButton(
                          label: 'Continue',
                          enabled: state.canContinue && !state.submitting,
                          onTap: cubit.next,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final AwardState state;
  final AwardCubit cubit;
  const _StepBody({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final pad = const EdgeInsets.all(AppSpacing.screenPad);
    switch (state.step) {
      case 0:
        return ListView(
          padding: pad,
          children: [
            Text('Who is it for?', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s4),
            for (final u in state.recipients)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: AppCard(
                  onTap: () => cubit.selectRecipient(u.id),
                  border: Border.all(
                    color:
                        state.recipientId == u.id ? c.accentSolid : c.border,
                  ),
                  child: Row(
                    children: [
                      Avatar(
                        id: u.id,
                        name: u.displayName,
                        photoUrl: u.photoURL,
                        size: 40,
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.displayName,
                                style: AppType.h3(c),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(u.positionLabel,
                                style: AppType.sm(c),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      case 1:
        return ListView(
          padding: pad,
          children: [
            Text('What for?', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s4),
            // Tags first — each category is its own selectable tag.
            Text('TAGS', style: AppType.label(c)),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final cat in AuraCategory.values)
                  CategoryChip(
                    cat: cat,
                    selected: state.category == cat,
                    onTap: () => cubit.selectCategory(cat),
                  ),
              ],
            ),
            if (state.category != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryTag(cat: state.category!),
                    const SizedBox(height: AppSpacing.s2),
                    Text(state.category!.hint, style: AppType.bodyDim(c)),
                  ],
                ),
              ),
            ],
            // Comment after the tags.
            const SizedBox(height: AppSpacing.s5),
            Text('COMMENT', style: AppType.label(c)),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              style: AppType.body(c),
              onChanged: cubit.setComment,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surface,
                hintText: 'Add a comment…',
                hintStyle: AppType.bodyDim(c),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );
      case 2:
        return ListView(
          padding: pad,
          children: [
            Text('How much?', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepperButton(
                  icon: Icons.chevron_left,
                  enabled: state.points > state.minPoints,
                  onTap: () => cubit.setPoints(state.points - 1),
                ),
                SizedBox(
                  width: 96,
                  child: Center(child: AuraPoints(state.points, size: 56)),
                ),
                _StepperButton(
                  icon: Icons.chevron_right,
                  enabled: state.points < state.maxPoints,
                  onTap: () => cubit.setPoints(state.points + 1),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s7),
            Center(child: Text('TEMPLATES', style: AppType.label(c))),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final q in (state.isMentor
                    ? const [-10, -5, 5, 10]
                    : const [-1, 1]))
                  ActionChip(
                    label: Text(q > 0 ? '+$q' : '$q'),
                    onPressed: () => cubit.setPoints(q),
                  ),
              ],
            ),
          ],
        );
      default:
        return ListView(
          padding: pad,
          children: [
            Text('Review', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s4),
            AppCard(
              child: Row(
                children: [
                  if (state.recipient != null)
                    Avatar(
                      id: state.recipient!.id,
                      name: state.recipient!.displayName,
                      photoUrl: state.recipient!.photoURL,
                      size: 40,
                    ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(state.recipient?.displayName ?? '',
                        style: AppType.h3(c),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (state.category != null)
                    CategoryTag(cat: state.category!),
                  const SizedBox(width: AppSpacing.s3),
                  AuraPoints(state.points),
                ],
              ),
            ),
            if (state.comment.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              AppCard(
                child: Text(state.comment.trim(), style: AppType.body(c)),
              ),
            ],
          ],
        );
    }
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface2,
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
          ),
          child: Icon(icon, color: c.text),
        ),
      ),
    );
  }
}

class _MentorsOnlyView extends StatelessWidget {
  final VoidCallback onClose;
  const _MentorsOnlyView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: c.text),
            ),
          ),
          const Spacer(),
          Icon(Icons.workspace_premium_outlined, size: 56, color: c.textFaint),
          const SizedBox(height: AppSpacing.s4),
          Text('Mentors only', style: AppType.h2(c)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Only mentors can award Aura points.',
            textAlign: TextAlign.center,
            style: AppType.bodyDim(c),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Award button with a live cooldown countdown for rate-limited (non-mentor)
/// givers. Ticks every second while the cooldown is active.
class _AwardButton extends StatefulWidget {
  final AwardState state;
  final AwardCubit cubit;
  const _AwardButton({required this.state, required this.cubit});

  @override
  State<_AwardButton> createState() => _AwardButtonState();
}

class _AwardButtonState extends State<_AwardButton> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_AwardButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final until = widget.state.cooldownUntil;
    final active = until != null && DateTime.now().isBefore(until);
    if (active && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final u = widget.state.cooldownUntil;
        if (u == null || !DateTime.now().isBefore(u)) {
          _timer?.cancel();
          _timer = null;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _fmt(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final until = s.cooldownUntil;
    final remaining =
        until == null ? 0 : until.difference(DateTime.now()).inSeconds;
    final onCooldown = remaining > 0;
    final label = s.submitting
        ? 'Awarding…'
        : onCooldown
            ? 'Wait ${_fmt(remaining)}'
            : 'Award ${s.points >= 0 ? '+' : ''}${s.points}';
    return _PrimaryButton(
      label: label,
      enabled: s.canContinue && !s.submitting && !onCooldown,
      onTap: widget.cubit.submit,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.accent1, c.accent2]),
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
          ),
          child: Text(
            label,
            style: AppType.bodyStrong(c).copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  final int points;
  const _SuccessDialog({required this.points});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-close once, after the pop animation settles.
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final points = widget.points;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.slow,
        curve: Curves.elasticOut,
        builder: (_, t, __) => Transform.scale(
          scale: t,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s7),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSpacing.rLg),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c.accent1, c.accent2]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: AppSpacing.s4),
                AuraPoints(points, size: 40),
                const SizedBox(height: AppSpacing.s2),
                Text('Aura awarded!', style: AppType.h3(c)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
