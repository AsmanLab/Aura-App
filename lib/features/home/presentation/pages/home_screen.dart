import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aura_app/features/auth/presentation/auth_providers.dart';
import 'package:aura_app/features/roulette/data/roulette_service.dart';
import 'package:aura_app/core/widgets/aura_card.dart';
import 'package:aura_app/core/widgets/quick_action_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final canSpin = ref.watch(canSpinRouletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AuraApp'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        actions: [
          IconButton(
            onPressed: () => context.push('/give-aura'),
            icon: const Icon(Icons.add),
            tooltip: 'Give Aura',
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(canSpinRouletteProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
                                    ? Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(fontSize: 24),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      user.displayName,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Aura Stats
                  Row(
                    children: [
                      Expanded(
                        child: AuraCard(
                          title: 'This Week',
                          value: user.currentWeekAura,
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AuraCard(
                          title: 'Total Aura',
                          value: user.totalAura,
                          icon: Icons.auto_awesome,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      QuickActionButton(
                        title: 'Give Aura',
                        subtitle: 'Reward someone',
                        icon: Icons.add_circle,
                        color: Colors.green,
                        onTap: () => context.push('/give-aura'),
                      ),
                      QuickActionButton(
                        title: 'Roulette',
                        subtitle: canSpin.maybeWhen(
                          data: (canSpin) => canSpin ? 'Spin now!' : 'Come back tomorrow',
                          orElse: () => 'Loading...',
                        ),
                        icon: Icons.casino,
                        color: Colors.orange,
                        enabled: canSpin.maybeWhen(
                          data: (canSpin) => canSpin,
                          orElse: () => false,
                        ),
                        onTap: () => context.go('/roulette'),
                      ),
                      QuickActionButton(
                        title: 'Leaderboard',
                        subtitle: 'See rankings',
                        icon: Icons.leaderboard,
                        color: Colors.blue,
                        onTap: () => context.go('/leaderboard'),
                      ),
                      QuickActionButton(
                        title: 'Profile',
                        subtitle: 'Your history',
                        icon: Icons.person,
                        color: Colors.purple,
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}