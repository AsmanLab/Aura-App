import 'package:flutter/material.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/knowledge_doc.dart';
import 'package:aura_app/core/domain/repositories/knowledge_repository.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'doc_icon.dart';

class KnowledgePage extends StatelessWidget {
  const KnowledgePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<KnowledgeDoc>>(
          future: sl<KnowledgeRepository>().getDocs(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const PageSkeleton();
            }
            final docs = snap.data!;
            final featured = docs.where((d) => d.featured).toList();
            final rest = docs.where((d) => !d.featured).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPad,
                AppSpacing.s4,
                AppSpacing.screenPad,
                120,
              ),
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back, color: c.text),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Text('Knowledge', style: AppType.h1(c)),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                for (final d in featured) _FeaturedCard(doc: d),
                const SectionLabel('All documents'),
                AppCard.flush(
                  child: Column(
                    children: [
                      for (var i = 0; i < rest.length; i++)
                        _DocRow(doc: rest[i], divider: i != rest.length - 1),
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

class _FeaturedCard extends StatelessWidget {
  final KnowledgeDoc doc;
  const _FeaturedCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      onTap: () => context.push('/aura/knowledge/article/${doc.id}'),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.accent1, c.accent2],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              docIcon(doc.icon),
              size: 96,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'START HERE',
                style: AppType.label(c).copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                doc.title,
                style: AppType.h2(c).copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Read guide ›',
                style: AppType.bodyStrong(c).copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final KnowledgeDoc doc;
  final bool divider;
  const _DocRow({required this.doc, required this.divider});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: () => context.push('/aura/knowledge/article/${doc.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(AppSpacing.rSm),
              ),
              child: Icon(docIcon(doc.icon), size: 20, color: c.accentSolid),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title, style: AppType.h3(c)),
                  Text('${doc.tag} · ${doc.readTime}', style: AppType.sm(c)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
