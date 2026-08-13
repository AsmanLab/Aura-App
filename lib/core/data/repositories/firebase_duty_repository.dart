import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/domain/entities/duty_day.dart';
import 'package:aura_app/core/domain/repositories/duty_repository.dart';
import 'package:aura_app/core/models/enums.dart';

class FirebaseDutyRepository implements DutyRepository {
  final FirebaseFirestore _db;

  FirebaseDutyRepository(this._db);

  @override
  Future<List<DutyDay>> getWeek() async {
    final snap = await _db.collection('duty_week').get();
    if (snap.docs.isEmpty) return [];

    final now = DateTime.now();
    final days = <DutyDay>[];

    for (final d in snap.docs) {
      final data = d.data();
      final day = data['day'] as String? ?? '';
      final date = data['date'] as String? ?? '';
      final month = data['month'] as int? ?? now.month;
      final year = data['year'] as int? ?? now.year;
      final personId = data['personId'] as String? ?? '';

      final isToday = day == _dayName(now) &&
          date == now.day.toString().padLeft(2, '0') &&
          month == now.month &&
          year == now.year;

      days.add(DutyDay(
        day: day,
        date: date,
        personId: personId,
        isToday: isToday,
      ));
    }

    days.sort(
        (a, b) => (int.tryParse(a.date) ?? 0).compareTo(int.tryParse(b.date) ?? 0));
    return days;
  }

  @override
  Future<void> assignInternsToWeek() async {
    final internsSnap = await _db
        .collection('users')
        .where('role', isEqualTo: Role.intern.name)
        .get();

    final interns = internsSnap.docs
        .map((d) => _InternDoc(d.id, d.data()['totalAura'] as int? ?? 0))
        .toList()
      ..sort((a, b) => a.aura.compareTo(b.aura));

    if (interns.isEmpty) return;

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    final existing = await _db.collection('duty_week').get();
    final existingDocs = {for (final d in existing.docs) d.id: d.id};

    final batch = _db.batch();
    for (var i = 0; i < days.length; i++) {
      final intern = interns[i % interns.length];
      final day = days[i];
      final dateObj = now.add(Duration(days: i - now.weekday + 1));
      final date = dateObj.day.toString().padLeft(2, '0');
      final docRef = _db.collection('duty_week').doc(
        existingDocs.containsKey(day) ? existingDocs[day]! : day,
      );

      batch.set(
        docRef,
        {
          'day': day,
          'date': date,
          'month': dateObj.month,
          'year': dateObj.year,
          'personId': intern.id,
          'aura': intern.aura,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  @override
  Future<List<ChecklistItem>> getChecklist() async {
    return [];
  }

  static String _dayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class _InternDoc {
  final String id;
  final int aura;

  _InternDoc(this.id, this.aura);
}
