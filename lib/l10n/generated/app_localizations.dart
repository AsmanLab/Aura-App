import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Bottom nav: Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav: Leaderboard tab
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get navBoard;

  /// Bottom nav: Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// FAB: give Aura
  ///
  /// In en, this message translates to:
  /// **'Aura'**
  String get fabAura;

  /// FAB: give Hearts
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get fabHearts;

  /// Home greeting
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String greeting(Object name);

  /// No description provided for @myAura.
  ///
  /// In en, this message translates to:
  /// **'My Aura'**
  String get myAura;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noAuraYet.
  ///
  /// In en, this message translates to:
  /// **'No Aura yet.'**
  String get noAuraYet;

  /// No description provided for @todaysAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Attendance'**
  String get todaysAttendance;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @doneBreak.
  ///
  /// In en, this message translates to:
  /// **'Done / break'**
  String get doneBreak;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @noUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No users yet.'**
  String get noUsersYet;

  /// No description provided for @duty.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get duty;

  /// No description provided for @onDutyNow.
  ///
  /// In en, this message translates to:
  /// **'ON DUTY NOW'**
  String get onDutyNow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @myShift.
  ///
  /// In en, this message translates to:
  /// **'My shift'**
  String get myShift;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @handoffNote.
  ///
  /// In en, this message translates to:
  /// **'Handoff note'**
  String get handoffNote;

  /// No description provided for @handoffHint.
  ///
  /// In en, this message translates to:
  /// **'What should the next shift know?'**
  String get handoffHint;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My notes about this shift'**
  String get myNotes;

  /// No description provided for @myNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your day, issues, updates...'**
  String get myNotesHint;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist · {done}/{total}'**
  String checklist(Object done, Object total);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @highlightColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight color'**
  String get highlightColor;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// No description provided for @enableQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Enable quiet hours'**
  String get enableQuietHours;

  /// No description provided for @quietHoursRange.
  ///
  /// In en, this message translates to:
  /// **'From 10 PM to 9 AM'**
  String get quietHoursRange;

  /// No description provided for @quietStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get quietStartTime;

  /// No description provided for @quietEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get quietEndTime;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// No description provided for @logOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of this account.'**
  String get logOutBody;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Gamified feedback system'**
  String get tagline;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed: {error}'**
  String signInFailed(Object error);

  /// No description provided for @giveReceive.
  ///
  /// In en, this message translates to:
  /// **'Give and receive aura points based on\nbehavior, collaboration, and helpfulness'**
  String get giveReceive;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @navKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get navKnowledge;

  /// No description provided for @navAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get navAdminPanel;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile.'**
  String get couldNotLoadProfile;

  /// No description provided for @auraHistory.
  ///
  /// In en, this message translates to:
  /// **'Aura history'**
  String get auraHistory;

  /// No description provided for @totalAura.
  ///
  /// In en, this message translates to:
  /// **'Total Aura'**
  String get totalAura;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(Object date);

  /// No description provided for @markAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance'**
  String get markAttendance;

  /// No description provided for @startLunchBreak.
  ///
  /// In en, this message translates to:
  /// **'Start lunch break'**
  String get startLunchBreak;

  /// No description provided for @backFromLunch.
  ///
  /// In en, this message translates to:
  /// **'Back from lunch'**
  String get backFromLunch;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @lunchStart.
  ///
  /// In en, this message translates to:
  /// **'Lunch start'**
  String get lunchStart;

  /// No description provided for @lunchEnd.
  ///
  /// In en, this message translates to:
  /// **'Lunch end'**
  String get lunchEnd;

  /// No description provided for @removeOne.
  ///
  /// In en, this message translates to:
  /// **'Remove −1'**
  String get removeOne;

  /// No description provided for @addOne.
  ///
  /// In en, this message translates to:
  /// **'Add +1'**
  String get addOne;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All-time'**
  String get allTime;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @knowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get knowledge;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get noResults;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @heartsHistory.
  ///
  /// In en, this message translates to:
  /// **'Hearts history'**
  String get heartsHistory;

  /// No description provided for @giveHearts.
  ///
  /// In en, this message translates to:
  /// **'Give Hearts'**
  String get giveHearts;

  /// No description provided for @heartsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String heartsLeft(Object count);

  /// No description provided for @noHeartsYet.
  ///
  /// In en, this message translates to:
  /// **'No hearts yet.'**
  String get noHeartsYet;

  /// No description provided for @awardTitle.
  ///
  /// In en, this message translates to:
  /// **'Give Aura'**
  String get awardTitle;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reason;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promote;

  /// No description provided for @demote.
  ///
  /// In en, this message translates to:
  /// **'Demote'**
  String get demote;

  /// No description provided for @adminUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get adminUsersTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @attendanceMarked.
  ///
  /// In en, this message translates to:
  /// **'Attendance marked'**
  String get attendanceMarked;

  /// No description provided for @arrivedToday.
  ///
  /// In en, this message translates to:
  /// **'{present}/{total} arrived today'**
  String arrivedToday(Object present, Object total);

  /// No description provided for @noCheckinsYet.
  ///
  /// In en, this message translates to:
  /// **'No one has checked in yet.'**
  String get noCheckinsYet;

  /// No description provided for @didNotArrive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t arrive'**
  String get didNotArrive;

  /// No description provided for @onLunch.
  ///
  /// In en, this message translates to:
  /// **'On lunch'**
  String get onLunch;

  /// No description provided for @statusLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get statusLeft;

  /// No description provided for @statusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get statusArrived;

  /// No description provided for @arrivedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String arrivedAtTime(Object time);

  /// No description provided for @daysPresent.
  ///
  /// In en, this message translates to:
  /// **'Days present'**
  String get daysPresent;

  /// No description provided for @weekdaysInMonth.
  ///
  /// In en, this message translates to:
  /// **'Weekdays in month'**
  String get weekdaysInMonth;

  /// No description provided for @startLunch.
  ///
  /// In en, this message translates to:
  /// **'Start lunch'**
  String get startLunch;

  /// No description provided for @endLunch.
  ///
  /// In en, this message translates to:
  /// **'End lunch'**
  String get endLunch;

  /// No description provided for @lunchCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get lunchCommentHint;

  /// No description provided for @noRecordsForDay.
  ///
  /// In en, this message translates to:
  /// **'No records for this day'**
  String get noRecordsForDay;

  /// No description provided for @lunchBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Lunch break'**
  String get lunchBreakTitle;

  /// No description provided for @backFromLunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Back from lunch'**
  String get backFromLunchTitle;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @startLunchBtn.
  ///
  /// In en, this message translates to:
  /// **'Start lunch'**
  String get startLunchBtn;

  /// No description provided for @endLunchBtn.
  ///
  /// In en, this message translates to:
  /// **'End lunch'**
  String get endLunchBtn;

  /// No description provided for @noRecordsDay.
  ///
  /// In en, this message translates to:
  /// **'No records for this day'**
  String get noRecordsDay;

  /// No description provided for @arrivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrived: {time}'**
  String arrivedLabel(Object time);

  /// No description provided for @lunchStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Lunch started: {time}'**
  String lunchStartedLabel(Object time);

  /// No description provided for @lunchEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'Lunch ended: {time}'**
  String lunchEndedLabel(Object time);

  /// No description provided for @leftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left: {time}'**
  String leftLabel(Object time);

  /// No description provided for @notArrived.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t arrive'**
  String get notArrived;

  /// No description provided for @arrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String arrivedAt(Object time);

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanel;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @navHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get navHearts;

  /// No description provided for @noInternsYet.
  ///
  /// In en, this message translates to:
  /// **'No interns yet.'**
  String get noInternsYet;

  /// No description provided for @whoseHearts.
  ///
  /// In en, this message translates to:
  /// **'Whose hearts?'**
  String get whoseHearts;

  /// No description provided for @changeRecipient.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeRecipient;

  /// No description provided for @commentLabel.
  ///
  /// In en, this message translates to:
  /// **'COMMENT'**
  String get commentLabel;

  /// No description provided for @heartRemovalHint.
  ///
  /// In en, this message translates to:
  /// **'Required to remove a heart…'**
  String get heartRemovalHint;

  /// No description provided for @heartsOfMax.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max}'**
  String heartsOfMax(Object current, Object max);

  /// No description provided for @maxHeartsReached.
  ///
  /// In en, this message translates to:
  /// **'Already at max hearts (8/8).'**
  String get maxHeartsReached;

  /// No description provided for @mentorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Mentors only'**
  String get mentorsOnly;

  /// No description provided for @mentorsOnlyHearts.
  ///
  /// In en, this message translates to:
  /// **'Only mentors can change hearts.'**
  String get mentorsOnlyHearts;

  /// No description provided for @awardAura.
  ///
  /// In en, this message translates to:
  /// **'Award Aura'**
  String get awardAura;

  /// No description provided for @whoIsItFor.
  ///
  /// In en, this message translates to:
  /// **'Who is it for?'**
  String get whoIsItFor;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @whatFor.
  ///
  /// In en, this message translates to:
  /// **'What for?'**
  String get whatFor;

  /// No description provided for @tagsOptional.
  ///
  /// In en, this message translates to:
  /// **'TAGS (OPTIONAL)'**
  String get tagsOptional;

  /// No description provided for @howMuch.
  ///
  /// In en, this message translates to:
  /// **'How much?'**
  String get howMuch;

  /// No description provided for @templatesLabel.
  ///
  /// In en, this message translates to:
  /// **'TEMPLATES'**
  String get templatesLabel;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @noAuraLeftToday.
  ///
  /// In en, this message translates to:
  /// **'No aura left today — resets tomorrow.'**
  String get noAuraLeftToday;

  /// No description provided for @auraRemaining.
  ///
  /// In en, this message translates to:
  /// **'{current} of {max} aura left today'**
  String auraRemaining(Object current, Object max);

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get addCommentHint;

  /// No description provided for @awarding.
  ///
  /// In en, this message translates to:
  /// **'Awarding…'**
  String get awarding;

  /// No description provided for @dailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get dailyLimitReached;

  /// No description provided for @awardToPeople.
  ///
  /// In en, this message translates to:
  /// **'Award {sign}{pts} to {count} people'**
  String awardToPeople(Object sign, Object pts, Object count);

  /// No description provided for @awardSimple.
  ///
  /// In en, this message translates to:
  /// **'Award {sign}{pts}'**
  String awardSimple(Object sign, Object pts);

  /// No description provided for @awardedToPeople.
  ///
  /// In en, this message translates to:
  /// **'Aura awarded to {count} people!'**
  String awardedToPeople(Object count);

  /// No description provided for @awarded.
  ///
  /// In en, this message translates to:
  /// **'Aura awarded!'**
  String get awarded;

  /// No description provided for @mentorsOnlyAward.
  ///
  /// In en, this message translates to:
  /// **'Only mentors can award Aura points.'**
  String get mentorsOnlyAward;

  /// No description provided for @styleGallery.
  ///
  /// In en, this message translates to:
  /// **'Style Gallery'**
  String get styleGallery;

  /// No description provided for @gradientGlow.
  ///
  /// In en, this message translates to:
  /// **'Gradient & Glow'**
  String get gradientGlow;

  /// No description provided for @auraValuePoints.
  ///
  /// In en, this message translates to:
  /// **'Aura Value & Points'**
  String get auraValuePoints;

  /// No description provided for @widgetsSection.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgetsSection;

  /// No description provided for @colorsSection.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colorsSection;

  /// No description provided for @typographySection.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get typographySection;

  /// No description provided for @radiiSection.
  ///
  /// In en, this message translates to:
  /// **'Radii'**
  String get radiiSection;

  /// No description provided for @accentArrow.
  ///
  /// In en, this message translates to:
  /// **'accent1 → accent2'**
  String get accentArrow;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @allDocuments.
  ///
  /// In en, this message translates to:
  /// **'All documents'**
  String get allDocuments;

  /// No description provided for @startHere.
  ///
  /// In en, this message translates to:
  /// **'START HERE'**
  String get startHere;

  /// No description provided for @readGuide.
  ///
  /// In en, this message translates to:
  /// **'Read guide ›'**
  String get readGuide;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @updatedRecently.
  ///
  /// In en, this message translates to:
  /// **'Updated recently'**
  String get updatedRecently;

  /// No description provided for @noAccess.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get noAccess;

  /// No description provided for @cantChangeOwnRole.
  ///
  /// In en, this message translates to:
  /// **'You can\'t change your own role'**
  String get cantChangeOwnRole;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get newUser;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get roleLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @savedFor.
  ///
  /// In en, this message translates to:
  /// **'Saved for {name}'**
  String savedFor(Object name);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get nameLabel;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @hearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get hearts;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ru':
      return SRu();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
