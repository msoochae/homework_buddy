# CLAUDE.md — 가족용 숙제관리 앱 (HomeworkBuddy)

## 1. 프로젝트 개요
- 목적: 아이(채이현)가 학교/학원 숙제를 날짜별로 등록·진행관리하고, 부모(아빠/엄마)가 진척과 마감 임박 상황을 공유받는 **가족 전용 Android 앱**.
- 배포: Play 스토어 없이 **APK 직접 설치** (가족 기기 2~3대).
- 앱은 **하나**. 첫 실행 시 역할(아이 / 아빠 / 엄마)을 한 번 선택하고 기기에 저장한다. 설정에서 변경 가능.
- 언어: UI는 전부 **한국어**. 코드/주석/커밋 메시지는 영어 가능, 사용자 노출 문자열은 한국어.

## 2. 기술 스택 (변경 시 사용자 확인 필요)
- Flutter (최신 stable), Dart, 상태관리: Riverpod
- Firebase: Firestore(실시간 동기화), Cloud Messaging(FCM 푸시), Cloud Functions(Node.js/TypeScript, 알림 트리거), Anonymous Auth
- 로컬 저장: shared_preferences (역할, 가족코드)
- 달력: table_calendar
- 로컬 알림: flutter_local_notifications (FCM 수신 시 표시 + 마감 임박 리마인더), 예약은 `timezone` 패키지(`Asia/Seoul`)
- 푸시: firebase_messaging (data-only 메시지, 앱이 직접 표시)
- 날짜 처리: intl, 타임존은 `Asia/Seoul` 고정

## 3. 폴더 구조
```
lib/
  main.dart
  app/            # 라우팅, 테마, 역할 분기
  core/           # 날짜/기한 계산, 상수, 공휴일
  data/           # 모델, Firestore repository
  features/
    role_select/  # 역할 선택
    child/        # 홈(D-DAY), 달력, 등록, 상세
    parent/       # 대시보드, 목록, 알림내역
  services/       # 로컬 알림, FCM 래퍼 (테스트에서 가짜로 교체 가능)
  shared/         # 공용 위젯
assets/holidays_kr.json   # 공휴일 목록 (수동 관리, 연 1회 검토). 방학/재량휴업일은 부모가 앱 설정에서 추가
functions/        # Cloud Functions (TypeScript)
test/             # 기한 계산, 우선순위 정렬 단위 테스트
```

## 4. 도메인 규칙
**기한 계산, 등록 필수 요일, 상태 전이, D-DAY 우선순위의 상세 규칙과 테스트 케이스는 `.claude/skills/homework-rules/SKILL.md`를 따른다.** 기한/우선순위 관련 코드를 수정할 때는 반드시 해당 스킬을 먼저 읽는다.

요약:
- 카테고리: `school`(학교), `english`(영어), `math`(수학), `essay`(논술), `etc`(그외)
- 학교 = 영업일 매일 등록 / 영어 = 화·목·토 / 수학 = 월·수·금 / 논술 = 선택(기한 +7일) / 그외 = 선택
- 상태: `none`(숙제 없음), `registered`(등록), `in_progress`(진행, progress 0~100), `done`(완료)
- 수행 시간 관리: 숙제별 `startTime`, `endTime` (HH:mm) 등록/수정 지원

## 5. 데이터 모델 (Firestore)
```
families/{familyCode}/homeworks/{id}
  date: string         // 등록 기준일 "YYYY-MM-DD"
  category: string     // school|english|math|essay|etc
  title: string        // status=none 이면 "" 허용
  dueDate: string      // "YYYY-MM-DD" (none 이면 null)
  status: string       // none|registered|in_progress|done
  progress: number     // 0~100 (in_progress 일 때만 의미)
  startTime: string?   // "HH:mm"
  endTime: string?     // "HH:mm"
  createdBy: string    // child|dad|mom
  createdAt, updatedAt: timestamp
  completedAt: timestamp?

families/{familyCode}/lottery_data/tickets
  count: number        // 보유 뽑기권 수량

families/{familyCode}/lottery_inventory/{id}
  rank: number         // 1~7등
  reward: string       // 상품명
  emoji: string
  wonAt: timestamp
  isUsed: boolean

families/{familyCode}/messages/{id}
  senderRole: string   // child|dad|mom
  senderName: string   // 채이현, 아빠, 엄마
  text: string
  createdAt: timestamp

families/{familyCode}/devices/{deviceId}
  role: string         // child|dad|mom
  fcmToken: string

families/{familyCode}/settings/holidays
  dates: string[]      // 부모가 추가 가능 (방학, 재량휴업일)
```
- 같은 (date, category)에는 숙제를 여러 개 등록할 수 있으나, `none`(숙제 없음)은 해당 과목 하루에 1건만 허용하고 다른 숙제와 공존할 수 없다.
- 인증: Anonymous Auth + **가족코드**(6자리, 최초 설정 시 입력). Firestore Rules는 가족코드 경로 접근만 허용.

## 6. 화면 명세 (하단 3개 탭 구성)
앱은 하단 3개 탭(**숙제**, **뽑기**, **채팅**)으로 구성된다.

### 1. 숙제 탭
- **아이**:
  - 오늘의 숙제(홈) / 달력 보기 세그먼트 전환.
  - **전체 활성 숙제 조회**: 과거 등록된 지연 숙제(D<0) 및 오늘 마감 숙제(D-0)를 포함한 미완료 숙제를 D-DAY 우선순위로 표시.
  - **데일리 퍼펙트 스트릭**: 상단 불꽃(🔥) 배너로 연속 완료일 수 표시, 7일 연속 달성 시마다 보너스 뽑기권 1장 자동 지급.
  - **스와이프 퀵 완료**: 숙제 카드를 오른쪽으로 스와이프 시 햅틱 진동과 함께 즉시 100% 완료 처리.
  - **집중 뽀모도로 타이머**: 숙제 카드/상세에서 10분~60분 자유롭게 시간을 조절하여 집중 타이머 실행 가능, 완료 시 진행률 반영.
  - **칭찬 하이파이브 수신**: 부모가 보낸 칭찬 리액션을 실시간으로 감지하여 화면에 축하 팡파레 팝업 표시.
  - 항목 탭 → 진행률 슬라이더 / 완료 버튼 / 수행시간 수정 바텀시트.
  - 상단에 "오늘 미등록 과목" 경고 배너.
  - FAB(+)로 숙제 등록 화면 진입 (수행 시작/종료 시간 입력 지원, 시작<종료 시간 유효성 검증).
- **부모**:
  - 대시보드가 메인 화면: 오늘 과목별 등록 여부(미등록 경고), 이번 주 전체 진척률, 전체 숙제 현황(수행시간/진척률 포함), 임박/지연 목록, 최근 변경 이력.
  - **실시간 칭찬 보내기**: 대시보드에서 이현이에게 원클릭으로 칭찬 하이파이브(👏, ❤️, 🌟, 🍦) 전송.
  - 상단 액션 바: 달력 조회, 알림 내역, 부모 전용 설정(⚙️).

### 2. 뽑기 탭
- 아이의 동기부여를 위한 행운의 뽑기 시스템.
- 부모는 뽑기권(티켓)을 아이에게 선물할 수 있으며, 아이는 뽑기권을 사용하여 다이나믹한 박스 흔들기 애니메이션과 함께 뽑기 진행.
- 등수별 확률 명기:
  - 1등 (0.5%): 대박 소원권 🌟
  - 2등 (2.0%): 특급 선물 / 용돈 🎁
  - 3등 (4.0%): 자유시간 1시간 🎮
  - 4등 (7.5%): 맛있는 간식 세트 🍦
  - 5등 (10.0%): 숙제 10분 쉬기 ☕
  - 6등 (20.0%): 달콤한 사탕 / 초콜릿 🍬
  - 7등 (56.0%): 따뜻한 칭찬과 포옹 ❤️
- 보관함: 당첨된 아이템이 누적 저장되며, '사용' 버튼 클릭 시 보관함에서 삭제됨.

### 3. 채팅 탭
- 가족 간 실시간 소통 메신저 (카카오톡 스타일 말풍선 UI).
- 메시지 수신 시 로컬 푸시 알림 제공.

### 4. 기타 및 설정 규칙
- **부모 PIN**: 기기에서 부모(아빠/엄마) 역할을 *선택하는 순간*에만 4자리 PIN을 묻는다(`1102` 하드코딩).
- **역할 변경 메뉴**: 최초 부모(엄마, 아빠)로 선택 후 진입한 경우에만 설정 화면에 표시되며, 아이 화면에서는 완전히 숨김.

## 7. 알림 규칙
Cloud Function이 `homeworks` 문서의 create/update를 감지해 **부모 역할 기기들**에게 FCM 발송.
- 신규 등록: "채이현이 [수학] 숙제를 등록했어요: {title} (기한 {dueDate})"
- 숙제 없음 등록: "채이현이 [영어] 숙제 없음으로 등록했어요"
- 진행률 변경: "[수학] {title} 진행률 {progress}%"
- 완료: "채이현이 [학교] {title}을(를) 완료했어요 🎉"
- 마감 리마인더(앱 로컬 스케줄): D-1 저녁 7시, D-0 오전 8시에 미완료 숙제 알림 (아이/부모 모두)
- 알림 발송 대상은 변경자 본인 기기를 제외한다. (부모는 읽기 전용이라 변경자는 항상 아이 → 부모 기기만 대상)
- 진행률 알림은 60초 디바운스(마지막 변경만 발송). 상세 규칙: SKILL.md §6.
- 푸시는 data-only. 앱이 받아서 표시하므로 "알림 끄기" 설정이 클라이언트에서 적용된다.
- 리마인더는 같은 기한 숙제를 슬롯당 1건으로 묶는다.

## 8. 개발 명령어
```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release        # 결과: build/app/outputs/flutter-apk/app-release.apk
cd functions && npm install && npm test   # 알림 문구 단위 테스트
firebase deploy --only functions,firestore:rules   # Blaze 요금제 필요, 지역은 functions/src/index.ts REGION
```
설치/배포 상세: `INSTALL.md`.

## 9. 작업 원칙
- 한 번에 크게 만들지 말고 아래 마일스톤 순서로 진행, 각 단계 끝에 `flutter analyze`와 `flutter test` 통과 확인.
- **기한 계산과 우선순위 정렬은 UI와 분리된 순수 함수**로 작성하고, SKILL.md의 테스트 케이스를 단위 테스트로 반드시 포함.
- 날짜는 항상 `YYYY-MM-DD` 문자열(Asia/Seoul 기준)로 저장하고 비교. 타임스탬프로 날짜 비교 금지.
- Firebase 설정 파일(`google-services.json`)은 사용자가 제공한다. 임의로 생성하거나 커밋하지 말고, 없으면 사용자에게 요청한다. (`.gitignore` 추가)
- 아이가 사용하는 앱이므로 버튼은 크게, 문구는 쉬운 말로. 색상만으로 상태를 구분하지 말고 아이콘/텍스트 병행.
- 파괴적 작업(데이터 삭제, 스키마 변경)은 실행 전 사용자 확인.
- 불확실한 규칙은 임의로 정하지 말고 질문하거나 `TODO(question):` 주석과 함께 보고.

## 10. 마일스톤
1. Flutter 프로젝트 생성, 역할 선택, 로컬 저장, 기본 라우팅
2. 도메인 로직(기한 계산, 필수 등록 판정, 우선순위 정렬) + 단위 테스트
3. Firebase 연동(Auth, Firestore), 모델/Repository, 가족코드
4. 아이 화면: 등록 → 홈(D-DAY) → 달력 → 상세/진행률
5. 부모 화면: 대시보드, 목록, 설정
6. FCM + Cloud Functions 알림, 마감 리마인더
7. APK 빌드, 실기기 2대 테스트(아이/부모), 설치 가이드 작성

## 11. 결정 사항 / 미확정 사항
**결정됨**
- 알림 내역: 별도 기록 쌓지 않음 (숙제 변경에서 생성)
- 알림 끄기: 기기 내 저장만
- 부모 PIN: 부모 역할 선택 시에만, `1102` 하드코딩
- 공휴일: `assets/holidays_kr.json` 수동 관리 + 부모가 추가한 날. 영어/수학 "다음 수업"은 요일만 보고 공휴일 무시
- 전체 진척률 = 이번 주(월~일) 등록 숙제 평균 진행률 (추천안, SKILL.md §6-1)
- 진행률 알림 디바운스 60초 (추천안)
- 서명: 가족 배포용이라 debug 서명 유지 (추천안, INSTALL.md 참고)

**미확정**
- 완료한 숙제의 보관 기간(기본: 무기한)
- Cloud Functions 지역(기본 `asia-northeast3`, Firestore 위치와 같아야 함)
- 공휴일 JSON의 2027년 이후 항목 (연 1회 직접 검토 필요)
- FCM 토큰 API: 현재 `getToken`(deprecated 표시, 서버와 호환). 신규 FID 방식 이전은 서버와 함께
