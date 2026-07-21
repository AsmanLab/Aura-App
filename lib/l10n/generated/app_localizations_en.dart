// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navBoard => 'Board';

  @override
  String get navProfile => 'Profile';

  @override
  String get fabAura => 'Aura';

  @override
  String get fabHearts => 'Hearts';

  @override
  String greeting(Object name) {
    return 'Hi, $name';
  }

  @override
  String get myAura => 'My Aura';

  @override
  String get seeAll => 'See all';

  @override
  String get noAuraYet => 'No Aura yet.';

  @override
  String get todaysAttendance => 'Today\'s Attendance';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String get doneBreak => 'Done / break';

  @override
  String get absent => 'Absent';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get noUsersYet => 'No users yet.';

  @override
  String get duty => 'Duty';

  @override
  String get onDutyNow => 'ON DUTY NOW';

  @override
  String get thisWeek => 'This week';

  @override
  String get myShift => 'My shift';

  @override
  String get active => 'Active';

  @override
  String get handoffNote => 'Handoff note';

  @override
  String get handoffHint => 'What should the next shift know?';

  @override
  String get addTask => 'Add task';

  @override
  String get taskName => 'Task name';

  @override
  String get myNotes => 'My notes about this shift';

  @override
  String get myNotesHint => 'Describe your day, issues, updates...';

  @override
  String checklist(Object done, Object total) {
    return 'Checklist · $done/$total';
  }

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get highlightColor => 'Highlight color';

  @override
  String get notifications => 'Notifications';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get enableQuietHours => 'Enable quiet hours';

  @override
  String get quietHoursRange => 'From 10 PM to 9 AM';

  @override
  String get quietStartTime => 'Start time';

  @override
  String get quietEndTime => 'End time';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutBody => 'You will be signed out of this account.';

  @override
  String get tagline => 'Gamified feedback system';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String signInFailed(Object error) {
    return 'Sign in failed: $error';
  }

  @override
  String get giveReceive =>
      'Give and receive aura points based on\nbehavior, collaboration, and helpfulness';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get navKnowledge => 'Knowledge';

  @override
  String get navAdminPanel => 'Admin Panel';

  @override
  String get navSettings => 'Settings';

  @override
  String get attendance => 'Attendance';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get couldNotLoadProfile => 'Could not load profile.';

  @override
  String get auraHistory => 'Aura history';

  @override
  String get totalAura => 'Total Aura';

  @override
  String memberSince(Object date) {
    return 'Member since $date';
  }

  @override
  String get markAttendance => 'Mark attendance';

  @override
  String get startLunchBreak => 'Start lunch break';

  @override
  String get backFromLunch => 'Back from lunch';

  @override
  String get present => 'Present';

  @override
  String get lunchStart => 'Lunch start';

  @override
  String get lunchEnd => 'Lunch end';

  @override
  String get removeOne => 'Remove −1';

  @override
  String get addOne => 'Add +1';

  @override
  String get continueBtn => 'Continue';

  @override
  String get allTime => 'All-time';

  @override
  String get month => 'Month';

  @override
  String get week => 'Week';

  @override
  String get knowledge => 'Knowledge';

  @override
  String get announcements => 'Announcements';

  @override
  String get milestones => 'Milestones';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results.';

  @override
  String get readMore => 'Read more';

  @override
  String get back => 'Back';

  @override
  String get heartsHistory => 'Hearts history';

  @override
  String get giveHearts => 'Give Hearts';

  @override
  String heartsLeft(Object count) {
    return '$count left';
  }

  @override
  String get noHeartsYet => 'No hearts yet.';

  @override
  String get awardTitle => 'Give Aura';

  @override
  String get recipient => 'Recipient';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get amount => 'Amount';

  @override
  String get reason => 'Reason (optional)';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get bio => 'Bio';

  @override
  String get role => 'Role';

  @override
  String get users => 'Users';

  @override
  String get promote => 'Promote';

  @override
  String get demote => 'Demote';

  @override
  String get adminUsersTitle => 'User management';

  @override
  String get ok => 'OK';

  @override
  String get calendar => 'Calendar';

  @override
  String get attendanceMarked => 'Attendance marked';

  @override
  String arrivedToday(Object present, Object total) {
    return '$present/$total arrived today';
  }

  @override
  String get noCheckinsYet => 'No one has checked in yet.';

  @override
  String get didNotArrive => 'Didn\'t arrive';

  @override
  String get onLunch => 'On lunch';

  @override
  String get statusLeft => 'Left';

  @override
  String get statusArrived => 'Arrived';

  @override
  String arrivedAtTime(Object time) {
    return 'Arrived at $time';
  }

  @override
  String get daysPresent => 'Days present';

  @override
  String get weekdaysInMonth => 'Weekdays in month';

  @override
  String get startLunch => 'Start lunch';

  @override
  String get endLunch => 'End lunch';

  @override
  String get lunchCommentHint => 'Comment (optional)';

  @override
  String get noRecordsForDay => 'No records for this day';

  @override
  String get lunchBreakTitle => 'Lunch break';

  @override
  String get backFromLunchTitle => 'Back from lunch';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get startLunchBtn => 'Start lunch';

  @override
  String get endLunchBtn => 'End lunch';

  @override
  String get noRecordsDay => 'No records for this day';

  @override
  String arrivedLabel(Object time) {
    return 'Arrived: $time';
  }

  @override
  String lunchStartedLabel(Object time) {
    return 'Lunch started: $time';
  }

  @override
  String lunchEndedLabel(Object time) {
    return 'Lunch ended: $time';
  }

  @override
  String leftLabel(Object time) {
    return 'Left: $time';
  }

  @override
  String get notArrived => 'Didn\'t arrive';

  @override
  String arrivedAt(Object time) {
    return 'Arrived at $time';
  }

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get history => 'History';

  @override
  String get noTransactionsYet => 'No transactions yet.';

  @override
  String get navHearts => 'Hearts';

  @override
  String get noInternsYet => 'No interns yet.';

  @override
  String get whoseHearts => 'Whose hearts?';

  @override
  String get changeRecipient => 'Change';

  @override
  String get commentLabel => 'COMMENT';

  @override
  String get heartRemovalHint => 'Required to remove a heart…';

  @override
  String heartsOfMax(Object current, Object max) {
    return '$current/$max';
  }

  @override
  String get maxHeartsReached => 'Already at max hearts (8/8).';

  @override
  String get mentorsOnly => 'Mentors only';

  @override
  String get mentorsOnlyHearts => 'Only mentors can change hearts.';

  @override
  String get awardAura => 'Award Aura';

  @override
  String get whoIsItFor => 'Who is it for?';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get whatFor => 'What for?';

  @override
  String get tagsOptional => 'TAGS (OPTIONAL)';

  @override
  String get howMuch => 'How much?';

  @override
  String get templatesLabel => 'TEMPLATES';

  @override
  String get review => 'Review';

  @override
  String get noAuraLeftToday => 'No aura left today — resets tomorrow.';

  @override
  String auraRemaining(Object current, Object max) {
    return '$current of $max aura left today';
  }

  @override
  String get addCommentHint => 'Add a comment…';

  @override
  String get awarding => 'Awarding…';

  @override
  String get dailyLimitReached => 'Daily limit reached';

  @override
  String awardToPeople(Object sign, Object pts, Object count) {
    return 'Award $sign$pts to $count people';
  }

  @override
  String awardSimple(Object sign, Object pts) {
    return 'Award $sign$pts';
  }

  @override
  String awardedToPeople(Object count) {
    return 'Aura awarded to $count people!';
  }

  @override
  String get awarded => 'Aura awarded!';

  @override
  String get mentorsOnlyAward => 'Only mentors can award Aura points.';

  @override
  String get styleGallery => 'Style Gallery';

  @override
  String get gradientGlow => 'Gradient & Glow';

  @override
  String get auraValuePoints => 'Aura Value & Points';

  @override
  String get widgetsSection => 'Widgets';

  @override
  String get colorsSection => 'Colors';

  @override
  String get typographySection => 'Typography';

  @override
  String get radiiSection => 'Radii';

  @override
  String get accentArrow => 'accent1 → accent2';

  @override
  String get allFilter => 'All';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get allDocuments => 'All documents';

  @override
  String get startHere => 'START HERE';

  @override
  String get readGuide => 'Read guide ›';

  @override
  String get notFound => 'Not found';

  @override
  String get updatedRecently => 'Updated recently';

  @override
  String get noAccess => 'No access';

  @override
  String get cantChangeOwnRole => 'You can\'t change your own role';

  @override
  String get newUser => 'New user';

  @override
  String get roleLabel => 'ROLE';

  @override
  String get saveChanges => 'Save changes';

  @override
  String savedFor(Object name) {
    return 'Saved for $name';
  }

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get nameLabel => 'NAME';

  @override
  String get yourNameHint => 'Your name';

  @override
  String get change => 'Change';

  @override
  String get you => 'You';

  @override
  String get hearts => 'Hearts';
}
