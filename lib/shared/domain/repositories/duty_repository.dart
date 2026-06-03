import '../entities/duty_day.dart';

abstract class DutyRepository {
  Future<List<DutyDay>> getWeek();
  Future<List<ChecklistItem>> getChecklist();
}
