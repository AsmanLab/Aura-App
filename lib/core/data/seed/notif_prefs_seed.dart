import 'package:aura_app/core/domain/entities/notif_pref.dart';

class NotifPrefsSeed {
  const NotifPrefsSeed._();

  static final List<NotifPref> prefs = [
    NotifPref(
      id: 'duty',
      icon: 'shield',
      label: 'Duty',
      labelRu: 'Дежурство',
      description: 'Shift reminders and handoffs.',
      descriptionRu: 'Напоминания о сменах и передачи дежурства.',
      enabled: true,
    ),
    NotifPref(
      id: 'aura',
      icon: 'sparkle',
      label: 'Aura',
      labelRu: 'Aura',
      description: 'When someone awards you points.',
      descriptionRu: 'Когда кто-то начисляет вам баллы.',
      enabled: true,
    ),
    NotifPref(
      id: 'hearts',
      icon: 'heart',
      label: 'Hearts',
      labelRu: 'Сердца',
      description: 'Heart changes and trial status.',
      descriptionRu: 'Изменения сердец и статус испытательного срока.',
      enabled: true,
    ),
    NotifPref(
      id: 'milestones',
      icon: 'trophy',
      label: 'Milestones',
      labelRu: 'Этапы',
      description: 'Rank changes and achievements.',
      descriptionRu: 'Изменения ранга и достижения.',
      enabled: true,
    ),
    NotifPref(
      id: 'announcements',
      icon: 'bell',
      label: 'Announcements',
      labelRu: 'Объявления',
      description: 'Team-wide news.',
      descriptionRu: 'Новости команды.',
      enabled: false,
    ),
  ];
}
