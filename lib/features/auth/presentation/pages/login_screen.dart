import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (p, n) => p.error != n.error && n.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.signInFailed(state.error ?? '')),
            backgroundColor: c.heart,
          ),
        );
      },
      builder: (context, state) {
        final loading = state.submitting;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppGradients.aura(c)),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.rLg),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/brand/app_logo.png',
                            height: 96,
                            width: 96,
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            'AuraApp',
                            style: AppType.h1(c).copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            s.tagline,
                            style: AppType.body(c).copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () =>
                                context.read<AuthCubit>().signInWithGoogle(),
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Image.asset(
                                'assets/images/google_logo.png',
                                height: 20,
                                width: 20,
                              ),
                        label: Text(
                          loading ? s.signingIn : s.continueWithGoogle,
                          style: AppType.bodyStrong(c).copyWith(color: c.text),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: c.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.rSm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      s.giveReceive,
                      textAlign: TextAlign.center,
                      style: AppType.sm(c).copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
