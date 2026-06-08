import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';

typedef _HomeData = ({
  UserModel? user,
  Person onDuty,
  List<AuraTransaction> history,
});

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<_HomeData> _load() async {
    final user = await sl<AuthRepository>().getUser();
    final onDuty = await sl<PeopleRepository>().getOnDuty();
    final history = user == null
        ? <AuraTransaction>[]
        : await sl<ProfileRepository>().getHistory(user.id);
    return (user: user, onDuty: onDuty, history: history);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_HomeData>(
          future: _load(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = snap.data!;
            final firstName = d.user?.displayName.split(' ').first ?? 'there';
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPad,
                AppSpacing.s4,
                AppSpacing.screenPad,
                120,
              ),
              children: [
                // Greeting
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wednesday, Jun 3', style: AppType.sm(c)),
                          Text('Hi, $firstName', style: AppType.h1(c)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/aura/settings'),
                      icon: Icon(Icons.notifications_none, color: c.text),
                    ),
                  ],
                ),

                const SectionLabel('On duty now'),
                AppCard(
                  onTap: () => context.push('/aura/duty'),
                  child: Row(
                    children: [
                      Avatar(id: d.onDuty.id, name: d.onDuty.name, size: 52),
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.onDuty.name, style: AppType.h3(c)),
                            Text(d.onDuty.position, style: AppType.sm(c)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Live',
                                style: AppType.sm(c).copyWith(color: c.success),
                              ),
                            ],
                          ),
                          Text('until 6 PM', style: AppType.sm(c)),
                        ],
                      ),
                    ],
                  ),
                ),

                SectionLabel(
                  'My Aura',
                  trailing: GestureDetector(
                    onTap: () => context.go('/aura/profile'),
                    child: Text('See all', style: AppType.sm(c)),
                  ),
                ),
                if (d.history.isEmpty)
                  AppCard(
                    child: Text('No Aura yet.', style: AppType.bodyDim(c)),
                  )
                else
                  AppCard.flush(
                    child: Column(
                      children: [
                        for (var i = 0; i < 3 && i < d.history.length; i++)
                          AuraTransactionTile(
                            txn: d.history[i],
                            divider: i != 2 && i != d.history.length - 1,
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
