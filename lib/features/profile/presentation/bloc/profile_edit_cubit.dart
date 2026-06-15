import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileEditState extends Equatable {
  final bool loading;
  final String displayName;

  /// Current remote photo (shown until a new one is picked).
  final String? photoURL;

  /// Newly picked photo bytes, not yet uploaded (preview + upload on save).
  final Uint8List? pickedPhoto;

  final bool saving;
  final bool saved;
  final String? error;

  const ProfileEditState({
    this.loading = true,
    this.displayName = '',
    this.photoURL,
    this.pickedPhoto,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  bool get canSave => !saving && displayName.trim().isNotEmpty;

  ProfileEditState copyWith({
    bool? loading,
    String? displayName,
    String? photoURL,
    Uint8List? pickedPhoto,
    bool? saving,
    bool? saved,
    String? error,
  }) => ProfileEditState(
    loading: loading ?? this.loading,
    displayName: displayName ?? this.displayName,
    photoURL: photoURL ?? this.photoURL,
    pickedPhoto: pickedPhoto ?? this.pickedPhoto,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading,
    displayName,
    photoURL,
    pickedPhoto,
    saving,
    saved,
    error,
  ];
}

class ProfileEditCubit extends Cubit<ProfileEditState> {
  final ProfileRepository _repo;
  final AuthRepository _auth;

  ProfileEditCubit(this._repo, this._auth) : super(const ProfileEditState()) {
    _load();
  }

  Future<void> _load() async {
    final me = await _auth.getUser();
    if (isClosed) return;
    if (me == null) {
      emit(state.copyWith(loading: false, error: 'Could not load profile.'));
      return;
    }
    emit(state.copyWith(
      loading: false,
      displayName: me.displayName,
      photoURL: me.photoURL,
    ));
  }

  void setName(String v) => emit(state.copyWith(displayName: v));
  void setPhoto(Uint8List bytes) => emit(state.copyWith(pickedPhoto: bytes));

  Future<void> save() async {
    if (!state.canSave) return;
    final uid = _auth.currentUser?.id;
    if (uid == null) return;
    emit(state.copyWith(saving: true, error: null));
    try {
      String? photoURL;
      if (state.pickedPhoto != null) {
        photoURL = await _repo.uploadPhoto(uid, state.pickedPhoto!);
      }
      await _repo.updateProfile(
        uid,
        displayName: state.displayName.trim(),
        photoURL: photoURL,
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}
