# 숙제버디 (HomeworkBuddy) 설치 및 배포 가이드

## 1. 사전 요구사항

1. **Flutter SDK 설치** (Flutter 3.22+ 권장)
   - [Flutter 공식 다운로드](https://docs.flutter.dev/get-started/install/windows)에서 설치 후 환경변수 PATH 등록
   - 터미널에서 `flutter doctor` 실행하여 Android 툴체인 확인

2. **Firebase 프로젝트 설정**
   - [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 생성 (예: `homework-buddy`)
   - **Firestore Database** 생성: 위치는 `asia-northeast3 (서울)` 권장, 시작 모드는 '프로덕션 모드'
   - **Authentication**: 로그인 방법 중 '익명(Anonymous)' 활성화
   - **Cloud Messaging (FCM)**: 프로젝트 설정에서 활성화
   - **Android 앱 등록**:
     - 패키지명: `com.family.homework_buddy`
     - 생성된 `google-services.json` 다운로드 후 `android/app/google-services.json` 위치에 저장

---

## 2. Cloud Functions & Firestore 보안 규칙 배포

```bash
# Firebase CLI 로그인 및 프로젝트 선택
npm install -g firebase-tools
firebase login
firebase use --add <프로젝트ID>

# Cloud Functions 종속성 설치 및 빌드
cd functions
npm install
npm test          # 알림 메시지 단위 테스트 확인

# Firestore 규칙 및 Functions 배포 (Blaze 요금제 필요)
cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

---

## 3. Flutter 앱 단위 테스트 및 빌드

```bash
# 종속성 패키지 다운로드
flutter pub get

# 도메인 규칙 단위 테스트 실행 (기한 계산, 우선순위 정렬, 미등록 판정)
flutter test

# 릴리스용 APK 빌드 (가족 배포용 debug 서명 사용)
flutter build apk --release
```

- **생성된 APK 파일 경로**:
  `build/app/outputs/flutter-apk/app-release.apk`

---

## 4. 기기 설치 및 초기 세팅 순서

1. **APK 전송 및 설치**:
   - `app-release.apk` 파일을 카카오톡/구글 드라이브 등을 통해 가족 스마트폰(2~3대)으로 전송
   - '출처를 알 수 없는 앱 설치' 허용 후 설치

2. **기기 1 (부모 스마트폰 - 최초 생성)**:
   - 앱 실행 후 **'아빠'** 또는 **'엄마'** 선택
   - 부모 PIN 입력: **`1102`** (하드코딩 기본값)
   - '새 가족 코드 만들기' 선택 → 화면에 표시되는 **6자리 영숫자 코드** 메모 (예: `X7K2M9`)

3. **기기 2 (아이 스마트폰 - 채이현)**:
   - 앱 실행 후 **'채이현 (아이)'** 선택 (PIN 필요 없음)
   - '코드로 참여하기' 선택 → 기기 1에서 발급받은 6자리 가족 코드 입력
   - 완료! 달력 및 홈 화면에서 숙제 등록 시작

4. **기기 3 (다른 부모 스마트폰)**:
   - 앱 실행 후 부모 역할 선택 → PIN `1102` → '코드로 참여하기'로 동일 코드 입력
