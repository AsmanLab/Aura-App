import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aura_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:aura_app/core/models/attendance_transaction.dart';

class AttendanceState extends Equatable {
  final bool loading;
  final bool canCheckIn;
  final bool canCheckOut;
  final bool canStartLunch;
  final bool canEndLunch;
  final bool isCheckingIn;
  final bool isCheckingOut;
  final bool isStartingLunch;
  final bool isEndingLunch;
  final List<AttendanceRecord> myRecords;
  final List<AttendanceStatus> todayStatuses;
  final String? error;

  const AttendanceState({
    this.loading = true,
    this.canCheckIn = false,
    this.canCheckOut = false,
    this.canStartLunch = false,
    this.canEndLunch = false,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
    this.isStartingLunch = false,
    this.isEndingLunch = false,
    this.myRecords = const [],
    this.todayStatuses = const [],
    this.error,
  });

  AttendanceState copyWith({
    bool? loading,
    bool? canCheckIn,
    bool? canCheckOut,
    bool? canStartLunch,
    bool? canEndLunch,
    bool? isCheckingIn,
    bool? isCheckingOut,
    bool? isStartingLunch,
    bool? isEndingLunch,
    List<AttendanceRecord>? myRecords,
    List<AttendanceStatus>? todayStatuses,
    String? error,
  }) =>
      AttendanceState(
        loading: loading ?? this.loading,
        canCheckIn: canCheckIn ?? this.canCheckIn,
        canCheckOut: canCheckOut ?? this.canCheckOut,
        canStartLunch: canStartLunch ?? this.canStartLunch,
        canEndLunch: canEndLunch ?? this.canEndLunch,
        isCheckingIn: isCheckingIn ?? this.isCheckingIn,
        isCheckingOut: isCheckingOut ?? this.isCheckingOut,
        isStartingLunch: isStartingLunch ?? this.isStartingLunch,
        isEndingLunch: isEndingLunch ?? this.isEndingLunch,
        myRecords: myRecords ?? this.myRecords,
        todayStatuses: todayStatuses ?? this.todayStatuses,
        error: error,
      );

  @override
  List<Object?> get props => [
        loading, canCheckIn, canCheckOut, canStartLunch, canEndLunch,
        isCheckingIn, isCheckingOut, isStartingLunch, isEndingLunch,
        myRecords, todayStatuses, error,
      ];
}

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repo;
  final String userId;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  String? _resolvedUserId;

  AttendanceCubit(this._repo, this.userId) : super(const AttendanceState()) {
    _resolvedUserId = userId;
    _init();
  }

  Future<void> _init() async {
    emit(state.copyWith(loading: true, canCheckIn: _repo.isWithinTimeWindow()));

    _subscriptions.add(
      _repo.watchMyAttendance(_resolvedUserId!).listen((records) {
        if (!isClosed) {
          final todayKey = _dateKey(DateTime.now().toUtc());
          final existingRecord = records.cast<AttendanceRecord?>().firstWhere(
            (r) => r?.dateKey == todayKey, orElse: () => null);
          
          emit(state.copyWith(
            myRecords: records,
            canCheckIn: existingRecord == null && _repo.isWithinTimeWindow(),
            canCheckOut: existingRecord != null && existingRecord.checkOutNote == null,
            canStartLunch: existingRecord != null && existingRecord.lunchStart == null && existingRecord.checkOutNote == null,
            canEndLunch: existingRecord != null && existingRecord.lunchStart != null && existingRecord.lunchEnd == null,
          ));
        }
      }, onError: (e) {
        if (!isClosed) emit(state.copyWith(error: e.toString()));
      }),
    );
    emit(state.copyWith(loading: false));
  }

  /// Call from AttendancePage.initState — starts the all-users stream only
  /// while the page is visible, not for the entire app session.
  void startTodayMonitoring() {
    if (_todayMonitoringStarted) return;
    _todayMonitoringStarted = true;
    _subscriptions.add(
      _repo.watchTodayStatuses().listen((statuses) {
        if (!isClosed) emit(state.copyWith(todayStatuses: statuses));
      }, onError: (e) {
        if (!isClosed) emit(state.copyWith(error: e.toString()));
      }),
    );
  }

  bool _todayMonitoringStarted = false;

  Future<void> checkIn() async {
    if (state.isCheckingIn || !state.canCheckIn) return;
    emit(state.copyWith(isCheckingIn: true, error: null));

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      await _repo.checkIn(position.latitude, position.longitude);
      emit(state.copyWith(isCheckingIn: false));
    } catch (e) {
      emit(state.copyWith(isCheckingIn: false, error: e.toString()));
    }
  }

  Future<void> checkOut(String note) async {
    if (state.isCheckingOut || !state.canCheckOut) return;
    emit(state.copyWith(isCheckingOut: true, error: null));

    try {
      await _repo.checkOut(note);
      emit(state.copyWith(isCheckingOut: false));
    } catch (e) {
      emit(state.copyWith(isCheckingOut: false, error: e.toString()));
    }
  }

  Future<void> startLunch(String note) async {
    if (state.isStartingLunch || !state.canStartLunch) return;
    emit(state.copyWith(isStartingLunch: true, error: null));

    try {
      await _repo.startLunch(note);
      emit(state.copyWith(isStartingLunch: false));
    } catch (e) {
      emit(state.copyWith(isStartingLunch: false, error: e.toString()));
    }
  }

  Future<void> endLunch(String note) async {
    if (state.isEndingLunch || !state.canEndLunch) return;
    emit(state.copyWith(isEndingLunch: true, error: null));

    try {
      await _repo.endLunch(note);
      emit(state.copyWith(isEndingLunch: false));
    } catch (e) {
      emit(state.copyWith(isEndingLunch: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}

String _dateKey(DateTime date) {
  final utc = date.toUtc();
  return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
}