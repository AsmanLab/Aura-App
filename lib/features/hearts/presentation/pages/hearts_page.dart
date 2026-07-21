import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/hearts_row.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import '../bloc/hearts_cubit.dart';

class HeartsPage extends StatelessWidget {
  const HeartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        title: Text(s.hearts, style: AppType.h3(c)),
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<HeartsCubit, HeartsState>(
          listenWhen: (p, n) =>
              (!p.submitted && n.submitted) ||
              (p.error != n.error && n.error != null),
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!), backgroundColor: c.heart),
              );
              return;
            }
            HapticFeedback.mediumImpact();
            // Defer the pop out of the state-change callback (popping here can
            // assert mid-build/notification).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.pop();
            });
          },
          builder: (context, state) {
            if (state.loading) return const PageSkeleton();
            if (!state.canAward) return const _MentorsOnly();
            final cubit = context.read<HeartsCubit>();
            if (state.recipient == null) {
              return _RecipientList(
                recipients: state.recipients,
                onSelect: cubit.selectRecipient,
              );
            }
            return _HeartEditor(state: state, cubit: cubit);
          },
        ),
      ),
    );
  }
}

class _RecipientList extends StatelessWidget {
  final List recipients;
  final ValueChanged<String> onSelect;
  const _RecipientList({required this.recipients, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    if (recipients.isEmpty) {
      return Center(child: Text(s.noInternsYet, style: AppType.bodyDim(c)));
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPad),
      children: [
        Text(s.whoseHearts, style: AppType.h2(c)),
        const SizedBox(height: AppSpacing.s4),
        for (final u in recipients)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: AppCard(
              onTap: () => onSelect(u.id),
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
                    child: Text(u.displayName,
                        style: AppType.h3(c),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${u.hearts}/8', style: AppType.number(13, c)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HeartEditor extends StatelessWidget {
  final HeartsState state;
  final HeartsCubit cubit;
  const _HeartEditor({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final r = state.recipient!;
    final canAdd = r.hearts < 8 && !state.submitting;
    final canRemove =
        r.hearts > 0 && state.comment.trim().isNotEmpty && !state.submitting;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPad),
      children: [
        Row(
          children: [
            TextButton(
              onPressed: cubit.clearRecipient,
              child: Text(s.change, style: AppType.bodyStrong(c)),
            ),
          ],
        ),
        AppCard(
          child: Column(
            children: [
              Avatar(
                id: r.id,
                name: r.displayName,
                photoUrl: r.photoURL,
                size: 64,
                ring: true,
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(r.displayName, style: AppType.h3(c)),
              const SizedBox(height: AppSpacing.s4),
              Text('${r.hearts}/8', style: AppType.number(15, c)),
              const SizedBox(height: AppSpacing.s2),
              HeartsRow(count: r.hearts, size: 24),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Text(s.commentLabel, style: AppType.label(c)),
        const SizedBox(height: AppSpacing.s2),
        TextField(
          style: AppType.body(c),
          onChanged: cubit.setComment,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surface,
            hintText: s.heartRemovalHint,
            hintStyle: AppType.bodyDim(c),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.rSm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: state.submitting ? '…' : s.removeOne,
                color: c.heart,
                enabled: canRemove,
                onTap: () => cubit.submit(-1),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: _ActionButton(
                label: state.submitting ? '…' : s.addOne,
                color: c.success,
                enabled: canAdd,
                onTap: () => cubit.submit(1),
              ),
            ),
          ],
        ),
        if (r.hearts >= 8) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(s.maxHeartsReached, style: AppType.sm(c)),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: AppType.bodyStrong(
              Theme.of(context).extension<AppColors>()!,
            ).copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _MentorsOnly extends StatelessWidget {
  const _MentorsOnly();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 56, color: c.textFaint),
            const SizedBox(height: AppSpacing.s4),
            Text(s.mentorsOnly, style: AppType.h2(c)),
            const SizedBox(height: AppSpacing.s2),
            Text(s.mentorsOnlyHearts,
                textAlign: TextAlign.center, style: AppType.bodyDim(c)),
          ],
        ),
      ),
    );
  }
}
