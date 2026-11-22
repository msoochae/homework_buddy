import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { buildMessage } from './messages';

admin.initializeApp();

const REGION = 'asia-northeast3';
const db = admin.firestore();

export const onHomeworkWrite = functions
  .region(REGION)
  .firestore.document('families/{familyCode}/homeworks/{homeworkId}')
  .onWrite(async (change, context) => {
    const { familyCode, homeworkId } = context.params;
    if (!change.after.exists) return; // 삭제 시 알림 없음

    const after = change.after.data()!;
    const before = change.before.exists ? change.before.data()! : null;

    const isNew = !before;
    const statusChanged = !before || before.status !== after.status;
    const progressChanged =
      before && before.progress !== after.progress && after.status === 'in_progress';

    // 제목/기한만 변경된 경우 알림 없음
    if (!isNew && !statusChanged && !progressChanged) return;

    const msg = buildMessage(
      after.status,
      after.category,
      after.title,
      after.dueDate ?? null,
      after.progress,
    );

    // 진행률 변경: 60초 디바운스
    if (progressChanged && !statusChanged) {
      const debounceRef = db
        .collection('families')
        .doc(familyCode)
        .collection('_debounce')
        .doc(homeworkId);

      const now = admin.firestore.Timestamp.now();
      await debounceRef.set({ lastUpdated: now });
      await new Promise((resolve) => setTimeout(resolve, 60000));
      const snap = await debounceRef.get();
      if (!snap.exists) return;
      const data = snap.data()!;
      if (data.lastUpdated.toMillis() !== now.toMillis()) return;
      await debounceRef.delete();
    }

    // 부모 기기 FCM 토큰 조회
    const devicesSnap = await db
      .collection('families')
      .doc(familyCode)
      .collection('devices')
      .where('role', 'in', ['dad', 'mom'])
      .get();

    const tokens = devicesSnap.docs
      .map((d) => d.data().fcmToken as string)
      .filter(Boolean);

    if (tokens.length === 0) return;

    // data-only FCM 전송
    await admin.messaging().sendEachForMulticast({
      tokens,
      data: {
        title: msg.title,
        body: msg.body,
        docId: homeworkId,
      },
    });
  });
