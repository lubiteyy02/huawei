# 附录A 核心代码片段

---

## A-1 全局公告服务（GlobalAnnouncerService）

> 文件路径：entry/src/main/ets/services/GlobalAnnouncerService.ets
> 功能：应用进程启动时初始化，常驻监听WebSocket同步事件，按事件类型写入AppStorage并触发TTS语音播报。

```typescript
export class GlobalAnnouncerService {
  private static instance: GlobalAnnouncerService | null = null
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance()
  private readonly tts: RealTtsService = RealTtsService.getInstance()
  private listener: CollaborationSyncEventListener | null = null
  private initialized: boolean = false

  static getInstance(): GlobalAnnouncerService {
    if (!GlobalAnnouncerService.instance) {
      GlobalAnnouncerService.instance = new GlobalAnnouncerService()
    }
    return GlobalAnnouncerService.instance
  }

  init(): void {
    if (this.initialized) return
    this.initialized = true
    this.bootstrapBackend()
    this.listener = (event: CollaborationSyncEvent): void => { this.handle(event) }
    this.viewModel.onSyncEvent(this.listener)
  }

  private handle(event: CollaborationSyncEvent): void {
    const myId = this.viewModel.getDeviceId()
    if (myId !== 'car-001') return
    if (event.sourceDeviceId === myId) return

    if (event.type === 'message.created') {
      const name = typeof event.payload.name === 'string' ? event.payload.name : ''
      const preview = typeof event.payload.preview === 'string' ? event.payload.preview : ''
      if (name === '' || preview === '') return
      void this.tts.speak(`收到一条来自${name}的短信。内容是：${preview}`)
      return
    }

    if (event.type === 'music.handover') {
      const songId = typeof event.payload.songId === 'number' ? event.payload.songId : -1
      const position = typeof event.payload.position === 'number' ? event.payload.position : 0
      const target = typeof event.payload.target === 'string' ? event.payload.target : ''
      if (songId < 0 || target !== myId) return
      const pending: PendingMusicHandover = {
        songId, position,
        title: `曲目 #${songId}`, artist: '',
        receivedAt: event.timestamp
      }
      AppStorage.setOrCreate<PendingMusicHandover>('pendingMusicHandover', pending)
      void this.tts.speak(`收到来自手机端的音乐续接申请。请到协同模块确认。`)
      return
    }

    if (event.type === 'navigation.handover') {
      const name = typeof event.payload.name === 'string' ? event.payload.name : ''
      const latitude = typeof event.payload.latitude === 'number' ? event.payload.latitude : 0
      const longitude = typeof event.payload.longitude === 'number' ? event.payload.longitude : 0
      if (name === '' || latitude === 0 || longitude === 0) return
      const pending: PendingNavHandover = {
        name, address: '', latitude, longitude,
        receivedAt: event.timestamp
      }
      AppStorage.setOrCreate<PendingNavHandover>('pendingNavHandover', pending)
      void this.tts.speak(`收到来自手机端的导航续接申请，目的地：${name}。`)
    }
  }
}
```

---

## A-2 WebSocket实时同步客户端（CollaborationSyncSocketService）

> 文件路径：entry/src/main/ets/services/CollaborationSyncSocketService.ets
> 功能：封装HarmonyOS WebSocket API，实现设备订阅、事件分发与自动重连。

```typescript
export class CollaborationSyncSocketService {
  private static instance: CollaborationSyncSocketService | null = null
  private readonly listeners: CollaborationSyncEventListener[] = []
  private client: CollaborationSocketClient | null = null
  private connected: boolean = false
  private reconnectTimer: number = -1
  private manualClose: boolean = false

  static getInstance(): CollaborationSyncSocketService {
    if (!CollaborationSyncSocketService.instance) {
      CollaborationSyncSocketService.instance = new CollaborationSyncSocketService()
    }
    return CollaborationSyncSocketService.instance
  }

  connect(url: string, userId: string, deviceId: string): void {
    this.manualClose = false
    if (!this.client) {
      this.client = webSocket.createWebSocket() as CollaborationSocketClient
      this.client.on('open', () => {
        this.connected = true
        const msg = JSON.stringify({ type: 'subscribe', userId, deviceId })
        this.client!.send(msg, () => {})
      })
      this.client.on('message', (_err: object, value?: object) => {
        const raw = typeof value === 'string' ? value as string : ''
        if (!raw) return
        try {
          const envelope = JSON.parse(raw) as SyncEnvelope
          if (envelope.type === 'sync-event' && envelope.event) {
            this.emit(envelope.event)
          }
        } catch { return }
      })
      this.client.on('close', () => {
        this.connected = false
        this.scheduleReconnect()
      })
    }
    this.client.connect(url, () => {})
  }

  private scheduleReconnect(): void {
    if (this.manualClose || this.reconnectTimer !== -1) return
    this.reconnectTimer = setTimeout((): void => {
      this.reconnectTimer = -1
      if (!this.manualClose && !this.connected && this.client) {
        this.client.connect(this.url, () => {})
      }
    }, 3000)
  }

  emit(event: CollaborationSyncEvent): void {
    this.listeners.forEach((listener) => listener(event))
  }
}
```

---

## A-3 后端协同广播中心（CollaborationSyncHub）

> 文件路径：backend/src/services/collaborationSyncHub.ts
> 功能：基于ws库的WebSocket Server，管理设备订阅映射，负责将协同事件广播至同账号所有在线设备。

```typescript
import { WebSocketServer, WebSocket } from 'ws';

const subscribedClients = new Map<WebSocket, { userId: string; deviceId: string }>();

export function initializeCollaborationSyncHub(server: import('http').Server): void {
  const wsServer = new WebSocketServer({ server, path: '/api/v1/sync/ws' });
  wsServer.on('connection', (socket) => {
    socket.on('message', (raw) => {
      const message = JSON.parse(raw.toString());
      if (message.type === 'subscribe') {
        subscribedClients.set(socket, {
          userId: message.userId,
          deviceId: message.deviceId
        });
        // 写入在线设备表 + 广播device.online
        upsertActiveDevice(message.deviceId, message.userId).then((record) => {
          broadcastEvent(createSyncEvent('device.online', {
            deviceId: message.deviceId, role: record.role
          }, message.deviceId, message.userId));
        });
      }
    });
    socket.on('close', () => {
      const info = subscribedClients.get(socket);
      subscribedClients.delete(socket);
      if (info) {
        markDeviceOffline(info.deviceId).then(() => {
          broadcastEvent(createSyncEvent('device.offline', {
            deviceId: info.deviceId
          }, info.deviceId, info.userId));
        });
      }
    });
  });
}

export function broadcastEvent(event: CollaborationSyncEvent): void {
  subscribedClients.forEach((clientInfo, socket) => {
    if (socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({ type: 'sync-event', event }));
    }
  });
}
```

---

## A-4 音乐跨端续接——手机端发起与车机端确认

> 文件路径：entry/src/main/ets/pages/CollaborationMusicPage.ets
> 功能：手机端提交续接申请（暂停本地播放），车机端读取AppStorage中的待确认申请并一键续接。

```typescript
// 手机端：提交续接申请
private async submitHandover(): Promise<void> {
  if (!this.nowPlaying || this.nowPlaying.songId <= 0) return;
  const snap = this.nowPlaying;
  const ok = await this.viewModel.handoverMusic(snap.songId, snap.position, 'car-001');
  if (!ok) return;
  // 让 MediaModule 立即暂停
  AppStorage.setOrCreate<MediaCommand>('mediaCommand', { type: 'pause' });
  const v = (AppStorage.get<number>('mediaCommandVersion') ?? 0) + 1;
  AppStorage.setOrCreate<number>('mediaCommandVersion', v);
  this.handoverSubmitted = true;
}

// 车机端：确认续接
private async acceptHandover(): Promise<void> {
  if (!this.pendingHandover) return;
  const p = this.pendingHandover;
  AppStorage.setOrCreate<PendingMusicHandover | null>('pendingMusicHandover', null);
  AppStorage.setOrCreate<MediaResumeRequest>('mediaResumeRequest', {
    songId: p.songId, position: p.position
  });
  const v = (AppStorage.get<number>('mediaTriggerVersion') ?? 0) + 1;
  AppStorage.setOrCreate<number>('mediaTriggerVersion', v);
  // 通知后端：车机已开始播放
  void this.viewModel.syncMusic(p.songId, true, p.position);
  router.back({ url: 'pages/Index' });
}
```

---

## A-5 车机端续接落地——加载并跳转播放

> 文件路径：entry/src/main/ets/view/MediaModule.ets
> 功能：收到MediaResumeRequest后加载目标曲目，等待AVPlayer就绪后seek到指定进度并自动播放。

```typescript
private async loadItemAndSeek(item: LocalMediaItem, positionMs: number): Promise<void> {
  await this.loadItem(item, true);
  // seek前先把歌词准备好
  if (!this.lrcCache.has(item.id)) {
    try { await this.loadLyricsForItem(item); } catch (_) {}
  }
  for (let i = 0; i < 30; i++) {
    if (this.totalTime > 0 && this.avPlayer) {
      this.isSeeking = true;
      try { await this.avPlayer.seek(positionMs); } catch (_) {}
      try { await this.avPlayer.play(); } catch (_) {}
      this.isPlaying = true;
      this.currentTime = positionMs;
      const idx = this.computeActiveLyricIndex(positionMs);
      if (idx !== this.activeLyricIndex) {
        this.activeLyricIndex = idx;
      } else {
        this.updateLyricTranslate(true);
      }
      this.writeMediaSyncState();
      return;
    }
    await new Promise<void>((r) => setTimeout(() => r(), 100));
  }
}
```

---

## A-6 歌词解析与卷帘同步渲染

> 文件路径：entry/src/main/ets/view/MediaModule.ets
> 功能：解析标准LRC歌词文件，实时计算当前高亮行并通过translateY动画实现卷帘滚动效果。

```typescript
// LRC歌词解析
private parseLrc(content: string): LyricLine[] {
  const lines: LyricLine[] = [];
  let offset: number = 0;
  const offsetMatch = content.match(/\[offset:\s*(-?\d+)\s*\]/i);
  if (offsetMatch) {
    offset = parseInt(offsetMatch[1], 10) || 0;
  }
  const timeRe = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;
  const rawLines = content.split(/\r?\n/);
  for (let r = 0; r < rawLines.length; r++) {
    const raw = rawLines[r];
    if (!raw) continue;
    const stamps: number[] = [];
    let m: RegExpExecArray | null;
    let lastEnd: number = 0;
    timeRe.lastIndex = 0;
    while ((m = timeRe.exec(raw)) !== null) {
      const min = parseInt(m[1], 10);
      const sec = parseInt(m[2], 10);
      const frac = parseInt((( m[3] || '0') + '000').substring(0, 3), 10);
      stamps.push(min * 60000 + sec * 1000 + frac + offset);
      lastEnd = m.index + m[0].length;
    }
    if (stamps.length === 0) continue;
    const text = raw.substring(lastEnd).trim();
    if (text.length === 0) continue;
    for (let i = 0; i < stamps.length; i++) {
      lines.push(new LyricLine(stamps[i], text));
    }
  }
  lines.sort((a, b) => a.time - b.time);
  return lines;
}

// 根据当前播放时间计算活跃歌词行索引
private computeActiveLyricIndex(time: number): number {
  const lyrics = this.getCurrentLyrics();
  if (lyrics.length === 0) return 0;
  let idx = 0;
  for (let i = 0; i < lyrics.length; i++) {
    if (time >= lyrics[i].time) idx = i;
    else break;
  }
  return idx;
}

// 卷帘动画：将活跃行居中显示
private updateLyricTranslate(animated: boolean): void {
  const target = this.LYRIC_CONTAINER_HEIGHT / 2
    - (this.activeLyricIndex + 0.5) * this.LYRIC_LINE_HEIGHT;
  if (animated) {
    animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
      this.lyricTranslateY = target;
    });
  } else {
    this.lyricTranslateY = target;
  }
}
```

---

## A-7 后端导航续接控制器

> 文件路径：backend/src/controllers/collaborationController.ts
> 功能：接收手机端导航续接请求，持久化续接任务并通过SyncHub广播至车机端。

```typescript
export async function navigationHandover(req: Request, res: Response) {
  const body = req.body as NavigationHandoverRequest;
  const name = (body.name || '').toString().trim();
  const address = (body.address || '').toString().trim();
  const latitude = Number(body.latitude);
  const longitude = Number(body.longitude);
  if (name === '' || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    res.status(400).json({ code: 400, message: 'name/latitude/longitude required' });
    return;
  }
  // 写入续接任务表
  const taskId = await insertContinuationTask(
    '导航', `去${name}`,
    address !== '' ? address : `坐标 ${latitude.toFixed(4)},${longitude.toFixed(4)}`,
    '手机'
  );
  // 广播至车机端
  broadcastEvent(createSyncEvent('navigation.handover', {
    name, address, latitude, longitude, taskId
  }, req.header('X-Device-Id'), req.header('X-User-Id'),
    'continuation', ['continuation', 'overview', 'log']
  ));
  res.json({ code: 0, message: 'ok', data: { taskId } });
}
```
