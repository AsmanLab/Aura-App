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
import '../../data/datasources/award_remote_data_source.dart'
    show auraDailyLimit;
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
              builder: (_) => _SuccessDialog(
                points: state.points,
                count: state.recipientIds.length,
              ),
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
        final selected = state.recipientIds;
        return ListView(
          padding: pad,
          children: [
            if (state.isMentor)
              Row(
                children: [
                  Expanded(child: Text('Who is it for?', style: AppType.h2(c))),
                  if (selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s3,
                        vertical: AppSpacing.s1,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c.accent1, c.accent2]),
                        borderRadius: BorderRadius.circular(AppSpacing.rChip),
                      ),
                      child: Text(
                        '${selected.length} selected',
                        style: AppType.sm(c).copyWith(color: Colors.white),
                      ),
                    ),
                ],
              )
            else
              Text('Who is it for?', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s4),
            for (final u in state.recipients)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: _RecipientTile(
                  user: u,
                  selected: selected.contains(u.id),
                  showCheckmark: state.isMentor,
                  onTap: () => cubit.toggleRecipient(u.id),
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
            Text('TAGS (OPTIONAL)', style: AppType.label(c)),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final cat in AuraCategory.values)
                  CategoryChip(
                    cat: cat,
                    selected: state.category == cat,
                    onTap: () => cubit.toggleCategory(cat),
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
            const SizedBox(height: AppSpacing.s5),
            Text('COMMENT', style: AppType.label(c)),
            const SizedBox(height: AppSpacing.s3),
            _CommentField(initial: state.comment, onChanged: cubit.setComment),
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
        final selected = state.selectedRecipients;
        return ListView(
          padding: pad,
          children: [
            Text('Review', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s4),
            AppCard.flush(
              child: Column(
                children: [
                  for (var i = 0; i < selected.length; i++)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      decoration: BoxDecoration(
                        border: i != selected.length - 1
                            ? Border(bottom: BorderSide(color: c.border))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Avatar(
                            id: selected[i].id,
                            name: selected[i].displayName,
                            photoUrl: selected[i].photoURL,
                            size: 40,
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: Text(
                              selected[i].displayName,
                              style: AppType.h3(c),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (state.category != null) ...[
                            CategoryTag(cat: state.category!),
                            const SizedBox(width: AppSpacing.s3),
                          ],
                          AuraPoints(state.points),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (state.comment.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              AppCard(
                child: Text(state.comment.trim(), style: AppType.body(c)),
              ),
            ],
            if (state.remainingToday != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Center(
                child: Text(
                  state.quotaReached
                      ? 'No aura left today — resets tomorrow.'
                      : '${state.remainingToday} of $auraDailyLimit aura left today',
                  style: AppType.sm(c).copyWith(color: c.textFaint),
                ),
              ),
            ],
          ],
        );
    }
  }
}

class _RecipientTile extends StatelessWidget {
  final dynamic user;
  final bool selected;
  final bool showCheckmark;
  final VoidCallback onTap;

  const _RecipientTile({
    required this.user,
    required this.selected,
    this.showCheckmark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
        onTap: onTap,
        border: Border.all(
          color: selected ? c.accentSolid : c.border,
          width: selected ? 2 : 1,
        ),
        child: Row(
          children: [
            Avatar(
              id: user.id,
              name: user.displayName,
              photoUrl: user.photoURL,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName,
                      style: AppType.h3(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(user.positionLabel,
                      style: AppType.sm(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (showCheckmark)
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: [c.accent1, c.accent2])
                      : null,
                  color: selected ? null : c.surface3,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.transparent : c.border,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
          ],
        ),
      );
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

class _CommentField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  const _CommentField({required this.initial, required this.onChanged});

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return TextField(
      controller: _ctrl,
      style: AppType.body(c),
      onChanged: widget.onChanged,
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
    );
  }
}

class _AwardButton extends StatelessWidget {
  final AwardState state;
  final AwardCubit cubit;
  const _AwardButton({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final count = state.recipientIds.length;
    final pts = state.points;
    final sign = pts >= 0 ? '+' : '';
    final label = state.submitting
        ? 'Awarding…'
        : state.quotaReached
            ? 'Daily limit reached'
            : count > 1
                ? 'Award $sign$pts to $count people'
                : 'Award $sign$pts';
    return _PrimaryButton(
      label: label,
      enabled: state.canContinue && !state.submitting && !state.quotaReached,
      onTap: cubit.submit,
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
  final int count;
  const _SuccessDialog({required this.points, required this.count});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    final count = widget.count;
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
                Text(
                  count > 1 ? 'Aura awarded to $count people!' : 'Aura awarded!',
                  style: AppType.h3(c),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
