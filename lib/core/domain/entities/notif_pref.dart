import 'package:equatable/equatable.dart';

class NotifPref extends Equatable {
  final String id;
  final String icon; // glyph name
  final String label;
  final String labelRu;
  final String description;
  final String descriptionRu;
  final bool enabled;

  const NotifPref({
    required this.id,
    required this.icon,
    required this.label,
    required this.labelRu,
    required this.description,
    required this.descriptionRu,
    this.enabled = true,
  });

  NotifPref copyWith({bool? enabled}) => NotifPref(
    id: id,
    icon: icon,
    label: label,
    labelRu: labelRu,
    description: description,
    descriptionRu: descriptionRu,
    enabled: enabled ?? this.enabled,
  );

  @override
  List<Object?> get props => [id, icon, label, labelRu, description, descriptionRu, enabled];
}
