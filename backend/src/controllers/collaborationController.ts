import { Request, Response } from 'express';
import { broadcastEvent, createSyncEvent } from '../services/collaborationSyncHub';

interface CollaborationOverview {
  phoneName: string;
  carName: string;
  syncStatus: string;
  lastSyncTime: string;
  unreadMessages: number;
  contactCount: number;
  musicCount: number;
  continuationCount: number;
  logs: string[];
}

interface CollaborationContact {
  id: number;
  name: string;
  phone: string;
  tag: string;
}

interface CollaborationMessageThread {
  id: number;
  name: string;
  preview: string;
  time: string;
  unread: number;
}

interface CollaborationMusicItem {
  id: number;
  title: string;
  artist: string;
  progress: number;
  device: string;
}

interface CollaborationContinuationTask {
  id: number;
  module: string;
  title: string;
  detail: string;
  device: string;
}

interface CollaborationResponse<T> {
  code: number;
  message: string;
  data: T;
}

interface MusicState {
  songId: number;
  playing: boolean;
  position: number;
  updatedAt: string;
}

interface ContactUpdateRequest {
  id: number;
  tag: string;
}

interface MessageReadRequest {
  threadId: number;
}

interface ContinuationResumeRequest {
  continuationId: number;
}

const overview: CollaborationOverview = {
  phoneName: 'Harmony Phone',
  carName: 'Harmony Car',
  syncStatus: '已连接',
  lastSyncTime: new Date().toISOString(),
  unreadMessages: 3,
  contactCount: 128,
  musicCount: 56,
  continuationCount: 2,
  logs: [
    '联系人：已同步 128 条',
    '短信：已同步最近 20 条会话',
    '音乐：已续接播放《七里香》',
    '应用续接：导航任务已同步到车机'
  ]
};

let contacts: CollaborationContact[] = [
  { id: 1, name: '李明', phone: '138-0000-0001', tag: '常用' },
  { id: 2, name: '王婷', phone: '138-0000-0002', tag: '最近' },
  { id: 3, name: '张伟', phone: '138-0000-0003', tag: '收藏' }
];

let threads: CollaborationMessageThread[] = [
  { id: 1, name: '妈妈', preview: '路上注意安全，到家告诉我', time: '09:12', unread: 1 },
  { id: 2, name: '同事-小周', preview: '会议资料已经发到群里了', time: '08:40', unread: 0 },
  { id: 3, name: '物业', preview: '明天早上停水，请提前储水', time: '昨天', unread: 2 }
];

let musicItems: CollaborationMusicItem[] = [
  { id: 1, title: '七里香', artist: '周杰伦', progress: 64, device: '手机正在播放' },
  { id: 2, title: '稻香', artist: '周杰伦', progress: 22, device: '车机可续接' },
  { id: 3, title: '晴天', artist: '周杰伦', progress: 89, device: '最近播放' }
];

let continuationTasks: CollaborationContinuationTask[] = [
  { id: 1, module: '导航', title: '去公司', detail: '已在手机上规划路线', device: '手机' },
  { id: 2, module: '音乐', title: '七里香', detail: '播放进度 01:08', device: '手机' }
];

let musicState: MusicState = {
  songId: 1,
  playing: true,
  position: 68000,
  updatedAt: new Date().toISOString()
};

let continuationCompletedIds: number[] = [];

const LOG_CAP = 8;

function wrap<T>(data: T): CollaborationResponse<T> {
  return {
    code: 0,
    message: 'ok',
    data
  };
}

function appendLog(message: string): void {
  const stamp = new Date().toLocaleTimeString('zh-CN', { hour12: false });
  overview.logs = [`${message} · ${stamp}`, ...overview.logs].slice(0, LOG_CAP);
  overview.lastSyncTime = new Date().toISOString();
}

export function addLog(req: Request, res: Response) {
  const body = (req.body || {}) as { message?: string; sourceLabel?: string };
  const message = typeof body.message === 'string' && body.message.trim() !== '' ? body.message : '手动触发同步';
  const label = typeof body.sourceLabel === 'string' && body.sourceLabel.trim() !== '' ? body.sourceLabel : (req.header('X-Device-Id') ?? 'unknown');
  appendLog(`[${label}] ${message}`);
  broadcastEvent(createSyncEvent('overview.refreshed', { logsHead: overview.logs[0] }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined));
  res.json(wrap({ version: Date.now(), logs: overview.logs }));
}

export function getOverview(req: Request, res: Response) {
  res.json(wrap({
    ...overview,
    lastSyncTime: new Date().toISOString(),
    logs: overview.logs
  }));
}

export function getContacts(req: Request, res: Response) {
  res.json(wrap(contacts));
}

export function updateContactTag(req: Request, res: Response) {
  const body = req.body as ContactUpdateRequest;
  const contact = contacts.find((item) => item.id === body.id);
  if (!contact) {
    res.status(404).json({ code: 404, message: 'contact not found', data: { version: Date.now() } });
    return;
  }

  contact.tag = body.tag;
  overview.logs = [`联系人已更新：${contact.name} → ${body.tag}`, ...overview.logs].slice(0, 4);
  broadcastEvent(createSyncEvent('contact.updated', { id: contact.id, tag: contact.tag }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined));
  res.json(wrap({ version: Date.now() }));
}

export function getMessageThreads(req: Request, res: Response) {
  res.json(wrap(threads));
}

export function markMessageRead(req: Request, res: Response) {
  const body = req.body as MessageReadRequest;
  const thread = threads.find((item) => item.id === body.threadId);
  if (!thread) {
    res.status(404).json({ code: 404, message: 'thread not found', data: { version: Date.now() } });
    return;
  }

  thread.unread = 0;
  overview.unreadMessages = Math.max(0, overview.unreadMessages - 1);
  overview.logs = [`短信已读：${thread.name}`, ...overview.logs].slice(0, 4);
  broadcastEvent(createSyncEvent('message.read', { threadId: thread.id, unread: thread.unread }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined));
  res.json(wrap({ version: Date.now() }));
}

export function getMusicLibrary(req: Request, res: Response) {
  res.json(wrap(musicItems));
}

export function getContinuationList(req: Request, res: Response) {
  const filtered = continuationTasks.filter((task) => !continuationCompletedIds.includes(task.id));
  res.json(wrap(filtered));
}

export function resumeContinuation(req: Request, res: Response) {
  const body = req.body as ContinuationResumeRequest;
  continuationCompletedIds = [...continuationCompletedIds, body.continuationId];
  overview.continuationCount = Math.max(0, overview.continuationCount - 1);
  overview.logs = [`续接任务完成：${body.continuationId}`, ...overview.logs].slice(0, 4);
  broadcastEvent(createSyncEvent('continuation.resumed', { continuationId: body.continuationId }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined));
  res.json(wrap({ version: Date.now() }));
}

export function getMusicState(req: Request, res: Response) {
  const meta = musicItems.find((item) => item.id === musicState.songId);
  res.json(wrap({
    songId: musicState.songId,
    playing: musicState.playing,
    position: musicState.position,
    updatedAt: musicState.updatedAt,
    title: meta ? meta.title : '',
    artist: meta ? meta.artist : '',
    sourceDevice: meta ? meta.device : ''
  }));
}

export function updateMusicState(req: Request, res: Response) {
  const { songId, playing, position, updatedAt } = req.body || {};

  if (typeof songId === 'number') {
    musicState = {
      songId,
      playing: !!playing,
      position: typeof position === 'number' ? position : 0,
      updatedAt: typeof updatedAt === 'string' ? updatedAt : new Date().toISOString()
    };
    broadcastEvent(createSyncEvent('music.stateChanged', { songId: musicState.songId, playing: musicState.playing ? 1 : 0, position: musicState.position }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined));
  }

  res.json(wrap({ version: Date.now(), musicState }));
}
