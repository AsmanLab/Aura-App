import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_app/core/models/roulette_spin.dart';

final rouletteServiceProvider = Provider<RouletteService>((ref) => RouletteService());

final canSpinRouletteProvider = FutureProvider<bool>((ref) {
  final rouletteService = ref.watch(rouletteServiceProvider);
  return rouletteService.canSpinToday();
});

class RouletteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  Future<bool> canSpinToday() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) return false;

    final userData = userDoc.data()!;
    final lastRouletteDate = userData['lastRouletteDate'] as Timestamp?;

    if (lastRouletteDate == null) return true;

    final lastSpinDate = lastRouletteDate.toDate();
    final today = DateTime.now();

    return !_isSameDay(lastSpinDate, today);
  }

  Future<RouletteSpin> spinRoulette() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final canSpin = await canSpinToday();
    if (!canSpin) {
      throw Exception('You can only spin once per day');
    }

    // Generate random result: 70% chance for +10, 30% chance for -5
    final result = _random.nextDouble() < 0.7 ? -10 : 5;
    final spin = RouletteSpin(
      userId: currentUser.uid,
      result: result,
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Update user's aura and last roulette date
    final userRef = _firestore.collection('users').doc(currentUser.uid);
    batch.update(userRef, {
      'currentWeekAura': FieldValue.increment(result),
      'totalAura': FieldValue.increment(result),
      'lastRouletteDate': FieldValue.serverTimestamp(),
    });

    // Record the spin
    batch.set(
      _firestore
          .collection('roulette_history')
          .doc(currentUser.uid)
          .collection('spins')
          .doc(),
      spin.toMap(),
    );

    await batch.commit();
    return spin;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}