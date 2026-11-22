import { buildMessage } from './messages';

describe('buildMessage', () => {
  it('신규 등록 알림', () => {
    const msg = buildMessage('registered', 'school', '독후감', '2026-11-20', 0);
    expect(msg.title).toBe('채이현이 [학교] 숙제를 등록했어요: 독후감 (기한 11/20)');
  });

  it('숙제 없음 알림', () => {
    const msg = buildMessage('none', 'english', '', null, 0);
    expect(msg.title).toBe('채이현이 [영어] 숙제 없음으로 등록했어요');
  });

  it('진행률 알림', () => {
    const msg = buildMessage('in_progress', 'math', '연산문제', '2026-11-21', 60);
    expect(msg.title).toBe('[수학] 연산문제 진행률 60%');
  });

  it('완료 알림', () => {
    const msg = buildMessage('done', 'school', '독후감', '2026-11-20', 100);
    expect(msg.title).toBe('채이현이 [학교] 독후감을(를) 완료했어요 🎉');
  });
});
