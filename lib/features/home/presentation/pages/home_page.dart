import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/services/attendance_service.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/attendance_calendar.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/hearts_status.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isTakingAttendance = false;

  Future<void> _takeAttendance() async {
    if (_isTakingAttendance) return;

    setState(() {
      _isTakingAttendance = true;
    });

    try {
      if (!await _checkLocationPermission()) {
        throw Exception('Разрешение на определение местоположения отклонено');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _attendanceService.markAttendance(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Посещаемость успешно сохранена!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingAttendance = false;
        });
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  bool _canTakeAttendance() {
    return _attendanceService.isWithinTimeWindow();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final me = sl<AuthRepository>().currentUser;
    final uid = me?.id;
    final firstName = me?.displayName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.accentSolid,
          backgroundColor: c.surface,
          onRefresh: () async {
            if (uid != null) await sl<ProfileRepository>().getHistory(uid);
          },
          child: StreamBuilder<UserModel?>(
            stream: uid == null
                ? const Stream.empty()
                : sl<ProfileRepository>().watchUser(uid),
            builder: (context, userSnap) {
              final user = userSnap.data;
              final isIntern = user?.role == Role.intern;
              return StreamBuilder<List<AuraTransaction>>(
                stream: uid == null
                    ? const Stream.empty()
                    : sl<ProfileRepository>().watchHistory(uid),
                builder: (context, snap) {
                  final loading =
                      snap.connectionState == ConnectionState.waiting;
                  final history = snap.data ?? const <AuraTransaction>[];
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPad,
                      AppSpacing.s4,
                      AppSpacing.screenPad,
                      120,
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: AppType.sm(c),
                          ),
                          Text('Hi, $firstName', style: AppType.h1(c)),
                        ],
                      ),
                      if (user != null && isIntern) ...[
                        const SizedBox(height: AppSpacing.s4),
                        HeartsStatus(count: user.hearts),
                      ],
                      SectionLabel('Attendance'),
                      StreamBuilder<List<AttendanceRecord>>(
                        stream: uid == null
                            ? const Stream.empty()
                            : _attendanceService.watchAttendance(uid),
                        builder: (context, attendanceSnap) {
                          final records = attendanceSnap.data ?? [];
                          return AttendanceCalendar(
                            records: records,
                            onCheckIn: _takeAttendance,
                            canCheckIn: _canTakeAttendance(),
                            isCheckingIn: _isTakingAttendance,
                          );
                        },
                      ),
                      if (user != null && user.canAward) ...[
                        SectionLabel('Today attendance'),
                        _AttendanceOverview(service: _attendanceService),
                      ],
                      SectionLabel(
                        'My Aura',
                        trailing: GestureDetector(
                          onTap: () => context.push('/aura/history'),
                          child: Text('See all', style: AppType.sm(c)),
                        ),
                      ),
                      if (loading)
                        const ListSkeleton(count: 3)
                      else if (history.isEmpty)
                        AppCard(
                          child: Text(
                            'No Aura yet.',
                            style: AppType.bodyDim(c),
                          ),
                        )
                      else
                        AppCard.flush(
                          child: Column(
                            children: [
                              for (var i = 0; i < 3 && i < history.length; i++)
                                AuraTransactionTile(
                                  txn: history[i],
                                  divider: i != 2 && i != history.length - 1,
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AttendanceOverview extends StatelessWidget {
  final AttendanceService service;

  const _AttendanceOverview({required this.service});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return StreamBuilder<List<AttendanceStatus>>(
      stream: service.watchTodayInternStatuses(),
      builder: (context, snapshot) {
        final statuses = snapshot.data ?? const <AttendanceStatus>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            statuses.isEmpty) {
          return const ListSkeleton(count: 3);
        }

        if (statuses.isEmpty) {
          return AppCard(
            child: Text('No interns found.', style: AppType.bodyDim(c)),
          );
        }

        final present = statuses.where((s) => s.isPresent).length;

        return AppCard.flush(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$present/${statuses.length} arrived today',
                        style: AppType.bodyStrong(c),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(DateTime.now()),
                      style: AppType.sm(c),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < statuses.length; i++)
                _AttendanceStatusRow(
                  status: statuses[i],
                  divider: i != statuses.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceStatusRow extends StatelessWidget {
  final AttendanceStatus status;
  final bool divider;

  const _AttendanceStatusRow({required this.status, required this.divider});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final record = status.record;
    final present = record != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        children: [
          Avatar(
            id: status.user.id,
            name: status.user.displayName,
            photoUrl: status.user.photoURL,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.user.displayName, style: AppType.h3(c)),
                Text(
                  present
                      ? 'Arrived at ${DateFormat('HH:mm').format(record.timestamp)}'
                      : 'Not arrived yet',
                  style: AppType.sm(c),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: present ? c.success.withValues(alpha: 0.14) : c.surface3,
              borderRadius: BorderRadius.circular(AppSpacing.rChip),
            ),
            child: Text(
              present ? 'Пришёл' : 'Не пришёл',
              style: AppType.sm(
                c,
              ).copyWith(color: present ? c.success : c.textDim),
            ),
          ),
        ],
      ),
    );
  }
}
