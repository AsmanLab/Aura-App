import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import '../utils/date_utils.dart';

class AuraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<void> giveAuraPoints({
    required String toUserId,
    required int points,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    
    if (currentUser.uid == toUserId) {
      throw Exception('Cannot give aura points to yourself');
    }

    if (points != 1 && points != -1) {
      throw Exception('Points must be +1 or -1');
    }

    if (comment.trim().isEmpty) {
      throw Exception('Comment is required');
    }

    final batch = _firestore.batch();
    final transactionId = _uuid.v4();
    final weekId = DateUtils.getCurrentWeekId();

    // Create transaction record
    final transaction = AuraTransaction(
      id: transactionId,
      fromUserId: currentUser.uid,
      toUserId: toUserId,
      points: points,
      comment: comment.trim(),
      timestamp: DateTime.now(),
      weekId: weekId,
    );

    batch.set(
      _firestore.collection('aura_transactions').doc(transactionId),
      transaction.toMap(),
    );

    // Update recipient's aura
    final userRef = _firestore.collection('users').doc(toUserId);
    batch.update(userRef, {
      'currentWeekAura': FieldValue.increment(points),
      'totalAura': FieldValue.increment(points),
    });

    await batch.commit();
  }

  Stream<List<UserModel>> getLeaderboard() {
    return _firestore
        .collection('users')
        .orderBy('currentWeekAura', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<AuraTransaction>> getAuraHistorySimple(String userId) {
    
    return _firestore
        .collection('aura_transactions')
        .where('toUserId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
              .map((doc) {
                try {
                  return AuraTransaction.fromMap(doc.data(), doc.id);
                } catch (e) {
                  return null;
                }
              })
              .where((transaction) => transaction != null)
              .cast<AuraTransaction>()
              .toList();
          
          // Sort in memory instead of using Firestore orderBy
          transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return transactions;
        });
  }

  Future<List<UserModel>> getAllUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
        .orderBy('displayName')
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}