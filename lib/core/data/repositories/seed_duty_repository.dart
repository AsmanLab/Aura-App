import 'package:aura_app/core/domain/entities/duty_day.dart';
import 'package:aura_app/core/domain/repositories/duty_repository.dart';
import '../seed/seed_data.dart';

class SeedDutyRepository implements DutyRepository {
  @override
  Future<List<DutyDay>> getWeek() async => SeedData.dutyWeek;

  @override
  Future<List<ChecklistItem>> getChecklist() async => SeedData.checklist;
}
