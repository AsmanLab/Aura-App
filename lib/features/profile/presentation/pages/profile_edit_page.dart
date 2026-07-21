import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import '../bloc/profile_edit_cubit.dart';

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.text,
        elevation: 0,
        title: Text(s.editProfile, style: AppType.h3(c)),
      ),
      body: BlocConsumer<ProfileEditCubit, ProfileEditState>(
        listenWhen: (p, n) => p.saved != n.saved || p.error != n.error,
        listener: (context, state) {
          if (state.saved) {
            context.pop();
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return const _EditForm();
        },
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm();

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ProfileEditCubit>();
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (x == null) return;
    cubit.setPhoto(await x.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<ProfileEditCubit>();
    final state = context.watch<ProfileEditCubit>().state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPad,
        AppSpacing.s5,
        AppSpacing.screenPad,
        AppSpacing.s7,
      ),
      children: [
        Center(
          child: GestureDetector(
            onTap: () => _pick(context),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                if (state.pickedPhoto != null)
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: MemoryImage(state.pickedPhoto!),
                  )
                else
                  Avatar(
                    id: cubit.hashCode.toString(),
                    name: state.displayName,
                    photoUrl: state.photoURL,
                    size: 96,
                    ring: true,
                  ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s2),
                  decoration: BoxDecoration(
                    color: c.accentSolid,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(s.nameLabel, style: AppType.label(c)),
        const SizedBox(height: AppSpacing.s2),
        _Field(
          initial: state.displayName,
          hint: s.yourNameHint,
          onChanged: cubit.setName,
        ),
        const SizedBox(height: AppSpacing.s7),
        GestureDetector(
          onTap: state.canSave ? cubit.save : null,
          child: Opacity(
            opacity: state.canSave ? 1 : 0.5,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.accent1, c.accent2]),
                borderRadius: BorderRadius.circular(AppSpacing.rSm),
              ),
              child: state.saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      s.save,
                      style: AppType.bodyStrong(c).copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Uncontrolled text field seeded once from cubit state (avoids cursor jumps).
class _Field extends StatefulWidget {
  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.initial,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard.flush(
      child: TextField(
        controller: _ctrl,
        style: AppType.body(c),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: c.surface,
          hintText: widget.hint,
          hintStyle: AppType.bodyDim(c),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
