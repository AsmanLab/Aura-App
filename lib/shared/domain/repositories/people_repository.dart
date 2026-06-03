import '../../models/enums.dart';
import '../entities/aura_entry.dart';
import '../entities/person.dart';

/// People, leaderboard, and Aura history. Backend-agnostic — implemented over
/// the seed now, swappable for Firestore later.
abstract class PeopleRepository {
  Future<List<Person>> getPeople();
  Future<Person> getMe();
  Future<Person> getOnDuty();
  Future<Person> getById(String id);

  /// Interns ranked by Aura, scaled by the filter period.
  Future<List<Person>> getLeaderboard(LbFilter filter);

  /// Aura feed for a person, newest first.
  Future<List<AuraEntry>> getHistory(String personId);
}
