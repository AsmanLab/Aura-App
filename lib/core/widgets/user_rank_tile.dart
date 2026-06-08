import 'package:aura_app/core/models/user_model.dart';
import 'package:flutter/material.dart';

class UserRankTile extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool isTopThree;

  const UserRankTile({
    super.key,
    required this.user,
    required this.rank,
    this.isTopThree = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          if (isTopThree)
            Positioned(
              right: -4,
              bottom: -4,
              child: Icon(
                Icons.emoji_events,
                size: 20,
                color: _getMedalColor(rank),
              ),
            ),
        ],
      ),
      title: Text(user.displayName),
      subtitle: Text('${user.currentWeekAura} aura'),
      trailing: Text(
        '#$rank',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getMedalColor(int place) {
    switch (place) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.transparent;
    }
  }
}
