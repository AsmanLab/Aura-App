import 'package:flutter/material.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/knowledge_doc.dart';
import 'package:aura_app/core/domain/repositories/knowledge_repository.dart';
import 'doc_icon.dart';

class ArticlePage extends StatelessWidget {
  final String id;
  const ArticlePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
      ),
      body: FutureBuilder<KnowledgeDoc?>(
        future: sl<KnowledgeRepository>().getDoc(id),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.connectionState == ConnectionState.done) {
              return Center(child: Text('Not found', style: AppType.body(c)));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPad,
              0,
              AppSpacing.screenPad,
              120,
            ),
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                ),
                child: Icon(docIcon(doc.icon), color: c.accentSolid),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(doc.title, style: AppType.h2(c)),
              Text('${doc.readTime} · Updated recently', style: AppType.sm(c)),
              const SizedBox(height: AppSpacing.s5),
              for (final b in doc.body) _Block(block: b),
            ],
          );
        },
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final DocBlock block;
  const _Block({required this.block});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: switch (block.type) {
        BlockType.heading => Text(block.text, style: AppType.h3(c)),
        BlockType.paragraph => Text(block.text, style: AppType.bodyDim(c)),
        BlockType.bullet => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: AppSpacing.s3),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.accentSolid,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: Text(block.text, style: AppType.body(c))),
            ],
          ),
        BlockType.callout => Container(
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: c.heart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.rSm),
              border: Border.all(color: c.heart.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite, size: 18, color: c.heart),
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: Text(block.text, style: AppType.body(c))),
              ],
            ),
          ),
      },
    );
  }
}
