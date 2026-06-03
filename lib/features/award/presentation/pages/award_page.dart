import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aura_value.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../../shared/widgets/category_chip.dart';
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
          listenWhen: (p, n) => !p.submitted && n.submitted,
          listener: (context, state) async {
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
                      _PrimaryButton(
                        label: state.step == 3
                            ? 'Award +${state.points}'
                            : 'Continue',
                        enabled: state.canContinue,
                        onTap: () =>
                            state.step == 3 ? cubit.submit() : cubit.next(),
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
            for (final p in state.interns)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: AppCard(
                  onTap: () => cubit.selectIntern(p.id),
                  border: Border.all(
                    color: state.internId == p.id ? c.accentSolid : c.border,
                  ),
                  child: Row(
                    children: [
                      Avatar(id: p.id, name: p.name, size: 40),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: AppType.h3(c),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(p.position, style: AppType.sm(c)),
                          ],
                        ),
                      ),
                      Text('${p.hearts}/8', style: AppType.number(13, c)),
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
          ],
        );
      case 2:
        return ListView(
          padding: pad,
          children: [
            Text('How much?', style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s5),
            Center(child: AuraPoints(state.points, size: 56)),
            const SizedBox(height: AppSpacing.s5),
            Slider(
              value: state.points.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              activeColor: c.accentSolid,
              onChanged: (v) => cubit.setPoints(v.round()),
            ),
            Wrap(
              spacing: AppSpacing.s2,
              children: [
                for (final q in [10, 25, 50, 75])
                  ActionChip(
                    label: Text('+$q'),
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
                  if (state.intern != null)
                    Avatar(
                      id: state.intern!.id,
                      name: state.intern!.name,
                      size: 40,
                    ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(state.intern?.name ?? '',
                        style: AppType.h3(c)),
                  ),
                  if (state.category != null)
                    CategoryTag(cat: state.category!),
                  const SizedBox(width: AppSpacing.s3),
                  AuraPoints(state.points),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
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
            const SizedBox(height: AppSpacing.s4),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Attach Linear issue', style: AppType.body(c)),
                  Switch(
                    value: state.attachLinear,
                    activeThumbColor: c.accentSolid,
                    onChanged: cubit.toggleLinear,
                  ),
                ],
              ),
            ),
          ],
        );
    }
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

class _SuccessDialog extends StatelessWidget {
  final int points;
  const _SuccessDialog({required this.points});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    // Auto-close after the pop animation settles.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (context.mounted) Navigator.of(context).pop();
    });
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
