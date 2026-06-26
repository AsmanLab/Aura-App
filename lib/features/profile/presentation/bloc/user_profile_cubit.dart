import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/services/user_profile_service.dart';

class UserProfileState extends Equatable {
  final bool loading;
  final UserModel? user;
  final List<AuraTransaction> auraHistory;
  final List<HeartTransaction> heartHistory;
  final List<AttendanceRecord> attendanceRecords;
  final String? error;

  const UserProfileState({
    this.loading = true,
    this.user,
    this.auraHistory = const [],
    this.heartHistory = const [],
    this.attendanceRecords = const [],
    this.error,
  });

  UserProfileState copyWith({
    bool? loading,
    UserModel? user,
    List<AuraTransaction>? auraHistory,
    List<HeartTransaction>? heartHistory,
    List<AttendanceRecord>? attendanceRecords,
    String? error,
  }) => UserProfileState(
    loading: loading ?? this.loading,
    user: user ?? this.user,
    auraHistory: auraHistory ?? this.auraHistory,
    heartHistory: heartHistory ?? this.heartHistory,
    attendanceRecords: attendanceRecords ?? this.attendanceRecords,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading, user, auraHistory, heartHistory, attendanceRecords, error,
  ];
}

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileService _service;
  final String userId;
  final List<StreamSubscription<dynamic>> _subs = [];

  UserProfileCubit(this._service, this.userId)
      : super(const UserProfileState()) {
    _init();
  }

  Future<void> _init() async {
    _subs.add(_service.watchUser(userId).listen((user) {
      if (!isClosed) emit(state.copyWith(user: user, loading: false));
    }, onError: (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: e.toString()));
    }));

    _subs.add(_service.watchAuraHistory(userId).listen((history) {
      if (!isClosed) emit(state.copyWith(auraHistory: history));
    }));

    _subs.add(_service.watchAttendance(userId).listen((records) {
      if (!isClosed) emit(state.copyWith(attendanceRecords: records));
    }));

    try {
      final hearts = await _service.getHeartHistory(userId);
      if (!isClosed) emit(state.copyWith(heartHistory: hearts));
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
