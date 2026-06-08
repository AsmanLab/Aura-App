import 'package:equatable/equatable.dart';

class DutyDay extends Equatable {
  final String day; // "Mon"
  final String date; // "01"
  final String personId;
  final bool isToday;

  const DutyDay({
    required this.day,
    required this.date,
    required this.personId,
    this.isToday = false,
  });

  @override
  List<Object?> get props => [day, date, personId, isToday];
}

class ChecklistItem extends Equatable {
  final String id;
  final String text;
  final bool done;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.done = false,
  });

  ChecklistItem copyWith({bool? done}) =>
      ChecklistItem(id: id, text: text, done: done ?? this.done);

  @override
  List<Object?> get props => [id, text, done];
}
