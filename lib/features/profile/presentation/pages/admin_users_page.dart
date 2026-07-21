import 'package:flutter/material.dart';

import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _demoMode = bool.fromEnvironment('DEMO', defaultValue: true);

class _DemoUsers {
  static List<UserModel> get list =>
      LeaderboardRemoteDataSourceImpl.demoUsersSnapshot;
}

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final s = S.of(context);
    final authMe = sl<AuthRepository>().currentUser;
    final uid = authMe?.id ?? (_demoMode ? 'demo-user' : null);

    if (uid == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(child: Text(s.noAccess)),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        title: Text(s.users),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _demoMode
            ? Stream.value(_DemoUsers.list.first)
            : sl<ProfileRepository>().watchUser(uid),
        builder: (context, meSnap) {
          final me = meSnap.data;
          final myRole = me?.role ?? Role.unknown;
          if (myRole != Role.admin) {
            return Center(child: Text(s.noAccess));
          }

          return StreamBuilder<List<UserModel>>(
            stream: _demoMode
                ? Stream.value(_DemoUsers.list)
                : FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                    .map((s) => s.docs
                        .map((d) => UserModel.fromMap(d.data(), d.id))
                        .toList()),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const PageSkeleton();
              }
              final users = snap.data ?? const <UserModel>[];
              if (users.isEmpty) {
                return Center(child: Text(s.noUsersYet));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPad,
                  AppSpacing.s4,
                  AppSpacing.screenPad,
                  120,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final divider = index != users.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                    child: _UserTile(user: user, divider: divider, currentUserId: uid),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final UserModel user;
  final bool divider;
  final String currentUserId;
  const _UserTile({required this.user, required this.divider, required this.currentUserId});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  late Role _role;

  @override
  void initState() {
    super.initState();
    _role = widget.user.role;
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_role == widget.user.role) return;
    if (widget.user.id == widget.currentUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.cantChangeOwnRole)),
      );
      return;
    }
    if (_demoMode) {
      final updated = LeaderboardRemoteDataSourceImpl.demoUsersSnapshot
          .map((u) => u.id == widget.user.id ? u.copyWith(role: _role) : u)
          .toList();
      LeaderboardRemoteDataSourceImpl.updateDemoUsers(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.savedFor(widget.user.displayName))),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'role': _role.name});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.savedFor(widget.user.displayName))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.errorPrefix(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final s = S.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(
                id: widget.user.id,
                name: widget.user.displayName,
                photoUrl: widget.user.photoURL,
                size: 44,
                ring: widget.user.role == Role.unknown,
                ringColor: widget.user.role == Role.unknown ? c.heart : null,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.displayName, style: AppType.h3(c)),
                    Text(widget.user.email, style: AppType.sm(c)),
                    if (widget.user.role == Role.unknown)
                      Text(s.newUser,
                          style: AppType.sm(c)
                              .copyWith(color: c.heart)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(s.roleLabel, style: AppType.label(c)),
          const SizedBox(height: AppSpacing.s2),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppSpacing.rSm),
                border: Border.all(color: c.border),
              ),
              child: DropdownButton<Role>(
                isExpanded: true,
                value: _role,
                onChanged: (r) {
                  if (r == null) return;
                  setState(() => _role = r);
                },
                items: [
                  for (final r in Role.values)
                    DropdownMenuItem(
                      value: r,
                      child: Text(r.label),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accentSolid,
                foregroundColor: Colors.white,
              ),
              child: Text(s.saveChanges),
            ),
          ),
        ],
      ),
    );
  }
}
