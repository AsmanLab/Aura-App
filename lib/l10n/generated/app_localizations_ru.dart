// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get navHome => 'Главная';

  @override
  String get navBoard => 'Рейтинг';

  @override
  String get navProfile => 'Профиль';

  @override
  String get fabAura => 'Аура';

  @override
  String get fabHearts => 'Сердца';

  @override
  String greeting(Object name) {
    return 'Привет, $name';
  }

  @override
  String get myAura => 'Моя Аура';

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get noAuraYet => 'Ауры пока нет.';

  @override
  String get todaysAttendance => 'Посещаемость сегодня';

  @override
  String get checkIn => 'Отметиться';

  @override
  String get checkOut => 'Уход';

  @override
  String get doneBreak => 'Готово / перерыв';

  @override
  String get absent => 'Отсутствует';

  @override
  String get leaderboard => 'Рейтинг';

  @override
  String get noUsersYet => 'Пользователей пока нет.';

  @override
  String get duty => 'Дежурство';

  @override
  String get onDutyNow => 'СЕЙЧАС ДЕЖУРИТ';

  @override
  String get thisWeek => 'На этой неделе';

  @override
  String get myShift => 'Моя смена';

  @override
  String get active => 'Активно';

  @override
  String get handoffNote => 'Заметка передачи смены';

  @override
  String get handoffHint => 'Что должна знать следующая смена?';

  @override
  String get addTask => 'Добавить задачу';

  @override
  String get taskName => 'Название задачи';

  @override
  String get myNotes => 'Мои заметки о смене';

  @override
  String get myNotesHint => 'Опишите свой день, проблемы, обновления...';

  @override
  String checklist(Object done, Object total) {
    return 'Чек-лист · $done/$total';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Оформление';

  @override
  String get darkMode => 'Тёмная тема';

  @override
  String get language => 'Язык';

  @override
  String get highlightColor => 'Цвет выделения';

  @override
  String get notifications => 'Уведомления';

  @override
  String get quietHours => 'Тихие часы';

  @override
  String get enableQuietHours => 'Включить тихие часы';

  @override
  String get quietHoursRange => 'С 22:00 до 9:00';

  @override
  String get quietStartTime => 'Время начала';

  @override
  String get quietEndTime => 'Время окончания';

  @override
  String get logOut => 'Выйти';

  @override
  String get logOutTitle => 'Выйти?';

  @override
  String get logOutBody => 'Вы выйдете из этой учётной записи.';

  @override
  String get tagline => 'Игровая система обратной связи';

  @override
  String get signingIn => 'Вход...';

  @override
  String get continueWithGoogle => 'Продолжить через Google';

  @override
  String signInFailed(Object error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get giveReceive =>
      'Дарите и получайте ауры за поведение,\nсотрудничество и полезность';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get navKnowledge => 'База знаний';

  @override
  String get navAdminPanel => 'Панель админа';

  @override
  String get navSettings => 'Настройки';

  @override
  String get attendance => 'Посещаемость';

  @override
  String get userNotFound => 'Пользователь не найден.';

  @override
  String get couldNotLoadProfile => 'Не удалось загрузить профиль.';

  @override
  String get auraHistory => 'История ауры';

  @override
  String get totalAura => 'Всего ауры';

  @override
  String memberSince(Object date) {
    return 'В команде с $date';
  }

  @override
  String get markAttendance => 'Отметить посещаемость';

  @override
  String get startLunchBreak => 'Начать обеденный перерыв';

  @override
  String get backFromLunch => 'Вернуться с обеда';

  @override
  String get present => 'Присутствует';

  @override
  String get lunchStart => 'Начало обеда';

  @override
  String get lunchEnd => 'Конец обеда';

  @override
  String get removeOne => 'Убрать −1';

  @override
  String get addOne => 'Добавить +1';

  @override
  String get continueBtn => 'Продолжить';

  @override
  String get allTime => 'За всё время';

  @override
  String get month => 'Месяц';

  @override
  String get week => 'Неделя';

  @override
  String get knowledge => 'База знаний';

  @override
  String get announcements => 'Объявления';

  @override
  String get milestones => 'Вехи';

  @override
  String get search => 'Поиск';

  @override
  String get noResults => 'Нет результатов.';

  @override
  String get readMore => 'Читать далее';

  @override
  String get back => 'Назад';

  @override
  String get heartsHistory => 'История сердец';

  @override
  String get giveHearts => 'Дать сердца';

  @override
  String heartsLeft(Object count) {
    return 'Осталось: $count';
  }

  @override
  String get noHeartsYet => 'Сердец пока нет.';

  @override
  String get awardTitle => 'Дать ауру';

  @override
  String get recipient => 'Получатель';

  @override
  String get selectCategory => 'Выберите категорию';

  @override
  String get amount => 'Количество';

  @override
  String get reason => 'Причина (необязательно)';

  @override
  String get submit => 'Отправить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get name => 'Имя';

  @override
  String get bio => 'О себе';

  @override
  String get role => 'Роль';

  @override
  String get users => 'Пользователи';

  @override
  String get promote => 'Повысить';

  @override
  String get demote => 'Понизить';

  @override
  String get adminUsersTitle => 'Управление пользователями';

  @override
  String get ok => 'ОК';

  @override
  String get calendar => 'Календарь';

  @override
  String get attendanceMarked => 'Посещаемость отмечена';

  @override
  String arrivedToday(Object present, Object total) {
    return '$present/$total пришли сегодня';
  }

  @override
  String get noCheckinsYet => 'Никто ещё не отметился.';

  @override
  String get didNotArrive => 'Не пришёл';

  @override
  String get onLunch => 'На обеде';

  @override
  String get statusLeft => 'Ушёл';

  @override
  String get statusArrived => 'Пришёл';

  @override
  String arrivedAtTime(Object time) {
    return 'Пришёл в $time';
  }

  @override
  String get daysPresent => 'Дней присутствия';

  @override
  String get weekdaysInMonth => 'Рабочих дней в месяце';

  @override
  String get startLunch => 'Начать обед';

  @override
  String get endLunch => 'Закончить обед';

  @override
  String get lunchCommentHint => 'Комментарий (необязательно)';

  @override
  String get noRecordsForDay => 'Нет записей за этот день';

  @override
  String get lunchBreakTitle => 'Обеденный перерыв';

  @override
  String get backFromLunchTitle => 'Вернулся с обеда';

  @override
  String get commentOptional => 'Комментарий (необязательно)';

  @override
  String get startLunchBtn => 'Начать обед';

  @override
  String get endLunchBtn => 'Закончить обед';

  @override
  String get noRecordsDay => 'Нет записей за этот день';

  @override
  String arrivedLabel(Object time) {
    return 'Пришёл: $time';
  }

  @override
  String lunchStartedLabel(Object time) {
    return 'Обед начат: $time';
  }

  @override
  String lunchEndedLabel(Object time) {
    return 'Обед закончен: $time';
  }

  @override
  String leftLabel(Object time) {
    return 'Ушёл: $time';
  }

  @override
  String get notArrived => 'Не пришёл';

  @override
  String arrivedAt(Object time) {
    return 'Пришёл в $time';
  }

  @override
  String get adminPanel => 'Админ панель';

  @override
  String get history => 'История';

  @override
  String get noTransactionsYet => 'Нет транзакций.';

  @override
  String get navHearts => 'Сердца';

  @override
  String get noInternsYet => 'Стажёров пока нет.';

  @override
  String get whoseHearts => 'Чьи сердца?';

  @override
  String get changeRecipient => 'Сменить';

  @override
  String get commentLabel => 'КОММЕНТАРИЙ';

  @override
  String get heartRemovalHint => 'Нужно, чтобы убрать сердце…';

  @override
  String heartsOfMax(Object current, Object max) {
    return '$current/$max';
  }

  @override
  String get maxHeartsReached => 'Уже максимум сердец (8/8).';

  @override
  String get mentorsOnly => 'Только для менторов';

  @override
  String get mentorsOnlyHearts => 'Только менторы могут изменять сердца.';

  @override
  String get awardAura => 'Дать ауру';

  @override
  String get whoIsItFor => 'Для кого?';

  @override
  String selectedCount(Object count) {
    return 'Выбрано: $count';
  }

  @override
  String get whatFor => 'За что?';

  @override
  String get tagsOptional => 'ТЕГИ (НЕОБЯЗАТЕЛЬНО)';

  @override
  String get howMuch => 'Сколько?';

  @override
  String get templatesLabel => 'ШАБЛОНЫ';

  @override
  String get review => 'Просмотр';

  @override
  String get noAuraLeftToday =>
      'Ауры на сегодня закончились — сбрасывается завтра.';

  @override
  String auraRemaining(Object current, Object max) {
    return '$current из $max ауры осталось на сегодня';
  }

  @override
  String get addCommentHint => 'Добавить комментарий…';

  @override
  String get awarding => 'Награждение…';

  @override
  String get dailyLimitReached => 'Дневной лимит исчерпан';

  @override
  String awardToPeople(Object sign, Object pts, Object count) {
    return 'Дать $sign$pts $count людям';
  }

  @override
  String awardSimple(Object sign, Object pts) {
    return 'Дать $sign$pts';
  }

  @override
  String awardedToPeople(Object count) {
    return 'Аура дана $count людям!';
  }

  @override
  String get awarded => 'Аура дана!';

  @override
  String get mentorsOnlyAward => 'Только менторы могут давать ауру.';

  @override
  String get styleGallery => 'Галерея стилей';

  @override
  String get gradientGlow => 'Градиент и свечение';

  @override
  String get auraValuePoints => 'Значение ауры и очки';

  @override
  String get widgetsSection => 'Виджеты';

  @override
  String get colorsSection => 'Цвета';

  @override
  String get typographySection => 'Типографика';

  @override
  String get radiiSection => 'Радиусы';

  @override
  String get accentArrow => 'accent1 → accent2';

  @override
  String get allFilter => 'Все';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get allDocuments => 'Все документы';

  @override
  String get startHere => 'НАЧНИТЕ ЗДЕСЬ';

  @override
  String get readGuide => 'Читать руководство ›';

  @override
  String get notFound => 'Не найдено';

  @override
  String get updatedRecently => 'Недавно обновлено';

  @override
  String get noAccess => 'Нет доступа';

  @override
  String get cantChangeOwnRole => 'Вы не можете изменить свою роль';

  @override
  String get newUser => 'Новый пользователь';

  @override
  String get roleLabel => 'РОЛЬ';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String savedFor(Object name) {
    return 'Сохранено для $name';
  }

  @override
  String errorPrefix(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get nameLabel => 'ИМЯ';

  @override
  String get yourNameHint => 'Ваше имя';

  @override
  String get change => 'Сменить';

  @override
  String get you => 'Вы';

  @override
  String get hearts => 'Сердца';
}
