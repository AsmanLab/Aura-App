import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import '../auth_providers.dart';

/// Shown while the persisted auth session is validated. Forces a token refresh
/// so an expired/revoked session signs out → the router sends it to /login.
/// On a valid session the router sends it to /home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: result flows back through authStateChanges, which the
    // router's redirect listens to.
    ref.read(authRepositoryProvider).ensureFreshToken();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.aura(c)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/app_logo.png', height: 96, width: 96),
              const SizedBox(height: AppSpacing.s6),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
