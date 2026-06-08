import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_app/core/services/aura_service.dart';
import 'package:aura_app/core/widgets/user_rank_tile.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        centerTitle: true,
      ),
      body: leaderboard.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No rankings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start giving aura points to see the leaderboard!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaderboardProvider);
            },
            child: Column(
              children: [
                // Top 3 Podium
                if (users.isNotEmpty) _buildPodium(context, users),
                
                // Rest of the leaderboard
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final rank = index + 1;
                      
                      return UserRankTile(
                        user: user,
                        rank: rank,
                        isTopThree: rank <= 3,
                      );
                    },
                  ),
                ),
              ],
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
              Text('Error loading leaderboard: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(leaderboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<dynamic> users) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (users.length > 1) _buildPodiumPlace(context, users[1], 2, 80),
          // 1st place
          if (users.isNotEmpty) _buildPodiumPlace(context, users[0], 1, 100),
          // 3rd place
          if (users.length > 2) _buildPodiumPlace(context, users[2], 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(BuildContext context, dynamic user, int place, double height) {
    Color getPlaceColor(int place) {
      switch (place) {
        case 1: return Colors.amber;
        case 2: return Colors.grey[400]!;
        case 3: return Colors.brown[300]!;
        default: return Colors.grey;
      }
    }

    IconData getPlaceIcon(int place) {
      switch (place) {
        case 1: return Icons.emoji_events;
        case 2: return Icons.military_tech;
        case 3: return Icons.workspace_premium;
        default: return Icons.star;
      }
    }

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${user.currentWeekAura} aura',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: height,
            decoration: BoxDecoration(
              color: getPlaceColor(place),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Icon(
              getPlaceIcon(place),
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}