export interface NotificationMessage {
  title: string;
  body: string;
}

const catDisplayName: Record<string, string> = {
  school: '학교',
  english: '영어',
  math: '수학',
  etc: '그외',
};

function formatDate(dateStr: string | null): string {
  if (!dateStr) return '';
  const [, month, day] = dateStr.split('-');
  return `${parseInt(month, 10)}/${parseInt(day, 10)}`;
}

export function buildMessage(
  status: string,
  category: string,
  title: string,
  dueDate: string | null,
  progress: number,
): NotificationMessage {
  const cat = catDisplayName[category] ?? category;

  if (status === 'none') {
    return {
      title: `채이현이 [${cat}] 숙제 없음으로 등록했어요`,
      body: '',
    };
  }

  if (status === 'done') {
    return {
      title: `채이현이 [${cat}] ${title}을(를) 완료했어요 🎉`,
      body: '',
    };
  }

  if (status === 'in_progress') {
    return {
      title: `[${cat}] ${title} 진행률 ${progress}%`,
      body: '',
    };
  }

  // registered (신규 등록)
  const dateLabel = dueDate ? ` (기한 ${formatDate(dueDate)})` : '';
  return {
    title: `채이현이 [${cat}] 숙제를 등록했어요: ${title}${dateLabel}`,
    body: '',
  };
}
