import 'package:aura_app/app/aura_app.dart';
import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupDi();
  runApp(const ProviderScope(child: AuraApp()));
}
