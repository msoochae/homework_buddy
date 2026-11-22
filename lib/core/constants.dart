class AppConstants {
  static const String parentPin = '1102';
  static const String appName = '숙제버디';
  static const String defaultTimezone = 'Asia/Seoul';
  static const String familiesCollection = 'families';
  static const String homeworksCollection = 'homeworks';
  static const String devicesCollection = 'devices';
  static const String messagesCollection = 'messages';
  static const String lotteryCollection = 'lottery';
  static const String lotteryInventoryCollection = 'lottery_inventory';
  static const String keyRole = 'role';
  static const String keyFamilyCode = 'family_code';
  static const String keyDeviceId = 'device_id';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const int reminderBaseId = 1000;
}

enum UserRole {
  child,
  dad,
  mom;

  String get displayName {
    switch (this) {
      case UserRole.child: return '채이현 (아이)';
      case UserRole.dad: return '아빠';
      case UserRole.mom: return '엄마';
    }
  }

  bool get isParent => this == UserRole.dad || this == UserRole.mom;
}

enum Category {
  school,
  english,
  math,
  essay,
  etc;

  String get displayName {
    switch (this) {
      case Category.school: return '학교';
      case Category.english: return '영어';
      case Category.math: return '수학';
      case Category.essay: return '논술';
      case Category.etc: return '그외';
    }
  }

  String get emoji {
    switch (this) {
      case Category.school: return '🏫';
      case Category.english: return '📖';
      case Category.math: return '🔢';
      case Category.essay: return '✍️';
      case Category.etc: return '📝';
    }
  }
}

enum HomeworkStatus {
  none,
  registered,
  inProgress,
  done;

  String get code {
    switch (this) {
      case HomeworkStatus.none: return 'none';
      case HomeworkStatus.registered: return 'registered';
      case HomeworkStatus.inProgress: return 'in_progress';
      case HomeworkStatus.done: return 'done';
    }
  }

  static HomeworkStatus fromCode(String code) {
    switch (code) {
      case 'none': return HomeworkStatus.none;
      case 'registered': return HomeworkStatus.registered;
      case 'in_progress': return HomeworkStatus.inProgress;
      case 'done': return HomeworkStatus.done;
      default: return HomeworkStatus.registered;
    }
  }

  String get displayName {
    switch (this) {
      case HomeworkStatus.none: return '숙제 없음';
      case HomeworkStatus.registered: return '등록됨';
      case HomeworkStatus.inProgress: return '진행 중';
      case HomeworkStatus.done: return '완료';
    }
  }
}
