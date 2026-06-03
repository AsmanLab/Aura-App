import '../../shared/domain/entities/aura_entry.dart';
import '../../shared/domain/entities/person.dart';
import '../../shared/domain/repositories/people_repository.dart';
import '../../shared/models/enums.dart';
import '../seed/seed_data.dart';

class SeedPeopleRepository implements PeopleRepository {
  @override
  Future<List<Person>> getPeople() async => SeedData.people;

  @override
  Future<Person> getMe() async =>
      SeedData.people.firstWhere((p) => p.isYou);

  @override
  Future<Person> getOnDuty() async =>
      SeedData.people.firstWhere((p) => p.id == SeedData.onDutyId);

  @override
  Future<Person> getById(String id) async =>
      SeedData.people.firstWhere((p) => p.id == id);

  @override
  Future<List<Person>> getLeaderboard(LbFilter filter) async {
    final interns =
        SeedData.people.where((p) => p.role == Role.intern).toList()
          ..sort((a, b) => b.aura.compareTo(a.aura));
    if (filter == LbFilter.allTime) return interns;
    // Scale scores so the filter visibly re-ranks (seed-only stand-in).
    return interns
        .map((p) => p.copyWith(aura: (p.aura * filter.scale).round()))
        .toList();
  }

  @override
  Future<List<AuraEntry>> getHistory(String personId) async {
    // Seed only carries Aibek's feed; return it for the demo user, else empty.
    if (personId == 'aibek') return SeedData.history;
    return const [];
  }
}
