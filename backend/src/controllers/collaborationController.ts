import { Request, Response } from 'express';
import { broadcastEvent, createSyncEvent } from '../services/collaborationSyncHub';
import {
  completeContinuationTask,
  getMusicStateRecord,
  getOverviewRecord,
  insertSyncLog,
  insertContinuationTask,
  listContacts,
  listContinuationTasks,
  insertThread,
  listMusicLibrary,
  listThreads,
  markThreadRead,
  recentLogs,
  replaceContacts,
  saveMusicStateRecord,
  saveOverviewRecord,
  updateContactTagById
} from '../repositories/collaborationRepository';

function mysqlDateTime(date: Date = new Date()): string {
  return date.toISOString().slice(0, 19).replace('T', ' ');
}

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
  title?: string;
  artist?: string;
  sourceDevice?: string;
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

interface MusicStateRequest {
  songId: number;
  playing: boolean;
  position: number;
  updatedAt?: string;
}

interface LogResponse {
  version: number;
  logs: string[];
}

function wrap<T>(data: T): CollaborationResponse<T> {
  return { code: 0, message: 'ok', data };
}

function parseLogs(value: string | null): string[] {
  if (!value) {
    return [];
  }
  try {
    const parsed = JSON.parse(value) as string[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

async function loadOverview(): Promise<CollaborationOverview> {
  const record = await getOverviewRecord();
  const recent = await recentLogs(8);
  return {
    phoneName: record ? record.phoneName : 'Harmony Phone',
    carName: record ? record.carName : 'Harmony Car',
    syncStatus: record ? record.syncStatus : '已连接',
    lastSyncTime: record ? record.lastSyncTime : mysqlDateTime(),
    unreadMessages: record ? record.unreadMessages : 0,
    contactCount: record ? record.contactCount : 0,
    musicCount: record ? record.musicCount : 0,
    continuationCount: record ? record.continuationCount : 0,
    logs: recent.length > 0 ? recent.map((item) => `[${item.sourceLabel}] ${item.messageText}`) : parseLogs(record ? record.logsJson : null)
  };
}

export async function addLog(req: Request, res: Response) {
  const body = (req.body || {}) as { message?: string; sourceLabel?: string };
  const message = typeof body.message === 'string' && body.message.trim() !== '' ? body.message : '手动触发同步';
  const label = typeof body.sourceLabel === 'string' && body.sourceLabel.trim() !== '' ? body.sourceLabel : (req.header('X-Device-Id') ?? 'unknown');
  await insertSyncLog(message, label);
  const overview = await loadOverview();
  await saveOverviewRecord({
    lastSyncTime: mysqlDateTime(),
    logsJson: JSON.stringify(overview.logs.slice(0, 8))
  });
  broadcastEvent(createSyncEvent('overview.refreshed', { logsHead: overview.logs[0] ?? '' }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'log', ['overview', 'log']));
  res.json(wrap<LogResponse>({ version: Date.now(), logs: overview.logs }));
}

export async function getOverview(req: Request, res: Response) {
  res.json(wrap(await loadOverview()));
}

export async function getContacts(req: Request, res: Response) {
  const rows = await listContacts();
  res.json(wrap(rows.map((item) => ({ id: item.id, name: item.name, phone: item.phone, tag: item.tag }))));
}

interface ContactBulkRequest {
  items: Array<{ name: string; phone: string; tag: string }>;
}

export async function bulkReplaceContacts(req: Request, res: Response) {
  const body = (req.body || {}) as ContactBulkRequest;
  const items = Array.isArray(body.items) ? body.items : [];
  await replaceContacts(items);
  const overview = await loadOverview();
  const updatedLogs = [`联系人批量同步：${items.length} 条`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({
    logsJson: JSON.stringify(updatedLogs),
    lastSyncTime: mysqlDateTime(),
    contactCount: items.length
  });
  broadcastEvent(createSyncEvent('contact.updated', { bulk: 1, count: items.length }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'contacts', ['contacts', 'overview', 'log']));
  res.json(wrap({ version: Date.now(), count: items.length }));
}

export async function updateContactTag(req: Request, res: Response) {
  const body = req.body as ContactUpdateRequest;
  const contactRows = await listContacts();
  const contact = contactRows.find((item) => item.id === body.id);
  if (!contact) {
    res.status(404).json({ code: 404, message: 'contact not found', data: { version: Date.now() } });
    return;
  }

  await updateContactTagById(body.id, body.tag);
  const overview = await loadOverview();
  const updatedLogs = [`联系人已更新：${contact.name} → ${body.tag}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: mysqlDateTime() });
  broadcastEvent(createSyncEvent('contact.updated', { id: contact.id, tag: body.tag }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'contacts', ['contacts', 'overview', 'log']));
  res.json(wrap({ version: Date.now() }));
}

export async function getMessageThreads(req: Request, res: Response) {
  const rows = await listThreads();
  res.json(wrap(rows.map((item) => ({ id: item.id, name: item.name, preview: item.preview, time: item.timeText, unread: item.unread }))));
}

interface MessageCreateRequest {
  name: string;
  preview: string;
}

interface NavigationHandoverRequest {
  name: string;
  address: string;
  latitude: number;
  longitude: number;
}

export async function navigationHandover(req: Request, res: Response) {
  const body = (req.body || {}) as NavigationHandoverRequest;
  const name = (body.name || '').toString().trim();
  const address = (body.address || '').toString().trim();
  const latitude = Number(body.latitude);
  const longitude = Number(body.longitude);
  if (name === '' || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    res.status(400).json({ code: 400, message: 'name/latitude/longitude required', data: { version: Date.now() } });
    return;
  }
  const overview = await loadOverview();
  const updatedLogs = [`导航续接：${name}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({
    logsJson: JSON.stringify(updatedLogs),
    lastSyncTime: mysqlDateTime()
  });
  // 写入续接任务，便于车机/手机在「应用续接」页看到
  let taskId = 0;
  try {
    taskId = await insertContinuationTask('导航', `去${name}`, address !== '' ? address : `坐标 ${latitude.toFixed(4)},${longitude.toFixed(4)}`, '手机');
  } catch (e) {
    console.error('[navigationHandover] insertContinuationTask failed', e);
  }
  broadcastEvent(createSyncEvent('navigation.handover', {
    name,
    address,
    latitude,
    longitude,
    taskId
  }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'continuation', ['continuation', 'overview', 'log']));
  res.json(wrap({ version: Date.now(), taskId }));
}

export async function createMessage(req: Request, res: Response) {
  const body = (req.body || {}) as MessageCreateRequest;
  const name = (body.name || '').toString().trim();
  const preview = (body.preview || '').toString().trim();
  if (name === '' || preview === '') {
    res.status(400).json({ code: 400, message: 'name and preview required', data: { version: Date.now() } });
    return;
  }
  const now = new Date();
  const timeText = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');
  const id = await insertThread(name, preview, timeText);
  const overview = await loadOverview();
  const updatedLogs = [`新短信：${name}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({
    logsJson: JSON.stringify(updatedLogs),
    lastSyncTime: mysqlDateTime()
  });
  broadcastEvent(createSyncEvent('message.created', { threadId: id, name, preview, time: timeText }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'messages', ['messages', 'overview', 'log']));
  res.json(wrap({ version: Date.now(), id }));
}

export async function markMessageRead(req: Request, res: Response) {
  const body = req.body as MessageReadRequest;
  const rows = await listThreads();
  const thread = rows.find((item) => item.id === body.threadId);
  if (!thread) {
    res.status(404).json({ code: 404, message: 'thread not found', data: { version: Date.now() } });
    return;
  }

  await markThreadRead(body.threadId);
  const overview = await loadOverview();
  const updatedLogs = [`短信已读：${thread.name}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: mysqlDateTime() });
  broadcastEvent(createSyncEvent('message.read', { threadId: thread.id, unread: 0 }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'messages', ['messages', 'overview', 'log']));
  res.json(wrap({ version: Date.now() }));
}

export async function getMusicLibrary(req: Request, res: Response) {
  const rows = await listMusicLibrary();
  res.json(wrap(rows.map((item) => ({ id: item.id, title: item.title, artist: item.artist, progress: item.progress, device: item.device }))));
}

export async function getContinuationList(req: Request, res: Response) {
  const rows = await listContinuationTasks();
  res.json(wrap(rows.map((item) => ({ id: item.id, module: item.moduleName, title: item.title, detail: item.detailText, device: item.deviceName }))));
}

export async function resumeContinuation(req: Request, res: Response) {
  const body = req.body as ContinuationResumeRequest;
  await completeContinuationTask(body.continuationId);
  const overview = await loadOverview();
  const updatedLogs = [`续接任务完成：${body.continuationId}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: mysqlDateTime() });
  broadcastEvent(createSyncEvent('continuation.resumed', { continuationId: body.continuationId }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'continuation', ['continuation', 'overview', 'log']));
  res.json(wrap({ version: Date.now() }));
}

export async function getMusicState(req: Request, res: Response) {
  const rows = await listMusicLibrary();
  const state = await getMusicStateRecord();
  const meta = rows.find((item) => item.id === (state ? state.songId : 0));
  res.json(wrap({
    songId: state ? state.songId : 0,
    playing: state ? state.playing === 1 : false,
    position: state ? state.position : 0,
    updatedAt: state ? state.updatedAt : mysqlDateTime(),
    title: meta ? meta.title : '',
    artist: meta ? meta.artist : '',
    sourceDevice: state ? state.sourceDevice : ''
  }));
}

export async function updateMusicState(req: Request, res: Response) {
  const body = req.body as MusicStateRequest;
  const rows = await listMusicLibrary();
  const meta = rows.find((item) => item.id === body.songId);
  const updatedAt = mysqlDateTime();
  await saveMusicStateRecord(body.songId, body.playing, body.position, req.header('X-Device-Id') ?? 'unknown', updatedAt);
  const overview = await loadOverview();
  const updatedLogs = [`音乐状态更新：${meta ? meta.title : body.songId}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: mysqlDateTime() });
  broadcastEvent(createSyncEvent('music.stateChanged', { songId: body.songId, playing: body.playing ? 1 : 0, position: body.position }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'music', ['music', 'overview', 'log']));
  res.json(wrap({ version: Date.now(), musicState: { songId: body.songId, playing: body.playing, position: body.position, updatedAt } }));
}

interface MusicHandoverRequest {
  songId: number;
  position: number;
  target: string;
}

export async function handoverMusic(req: Request, res: Response) {
  const body = req.body as MusicHandoverRequest;
  const rows = await listMusicLibrary();
  const meta = rows.find((item) => item.id === body.songId);
  const updatedAt = mysqlDateTime();
  await saveMusicStateRecord(body.songId, true, body.position, body.target, updatedAt);
  const overview = await loadOverview();
  const triggeredBy = req.header('X-Device-Id') ?? 'unknown';
  const updatedLogs = [`续接播放：${meta ? meta.title : body.songId} → ${body.target}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: mysqlDateTime() });
  broadcastEvent(createSyncEvent('music.handover', {
    songId: body.songId,
    position: body.position,
    target: body.target,
    triggeredBy
  }, triggeredBy, req.header('X-User-Id') ?? undefined, 'music', ['music', 'overview', 'log']));
  res.json(wrap({ version: Date.now() }));
}
