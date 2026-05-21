import { Router } from 'express';
import { broadcastEvent, createSyncEvent } from '../services/collaborationSyncHub';

const router = Router();

// 压测端点：仅论文测试章用，定稿前删除整个文件 + index.ts 里的注册
// 用法：POST /api/v1/_pressure/<事件类型>/<次数>
router.post('/_pressure/:type/:n', (req, res) => {
  const { type, n } = req.params;
  const count = Math.min(Number(n) || 1, 200);
  const startTs = Date.now();
  for (let i = 0; i < count; i++) {
    const evt = createSyncEvent(
      type as any,
      { test: true, idx: i, ts: Date.now() },
      'phone-001',
      '10001'
    );
    (evt as any).eventId = `pressure-${type}-${startTs}-${i}`;
    broadcastEvent(evt);
  }
  res.json({ ok: true, count, type, startTs });
});

export default router;