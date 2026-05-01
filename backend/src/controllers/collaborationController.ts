import { Request, Response } from 'express';
import { broadcastEvent, createSyncEvent } from '../services/collaborationSyncHub';
import {
  completeContinuationTask,
  getMusicStateRecord,
  getOverviewRecord,
  insertSyncLog,
  listContacts,
  listContinuationTasks,
  listMusicLibrary,
  listThreads,
  markThreadRead,
  recentLogs,
  saveMusicStateRecord,
  saveOverviewRecord,
  updateContactTagById
} from '../repositories/collaborationRepository';

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
    lastSyncTime: record ? record.lastSyncTime : new Date().toISOString(),
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
    lastSyncTime: new Date().toISOString(),
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
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: new Date().toISOString() });
  broadcastEvent(createSyncEvent('contact.updated', { id: contact.id, tag: body.tag }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'contacts', ['contacts', 'overview', 'log']));
  res.json(wrap({ version: Date.now() }));
}

export async function getMessageThreads(req: Request, res: Response) {
  const rows = await listThreads();
  res.json(wrap(rows.map((item) => ({ id: item.id, name: item.name, preview: item.preview, time: item.timeText, unread: item.unread }))));
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
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: new Date().toISOString() });
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
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: new Date().toISOString() });
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
    updatedAt: state ? state.updatedAt : new Date().toISOString(),
    title: meta ? meta.title : '',
    artist: meta ? meta.artist : '',
    sourceDevice: state ? state.sourceDevice : ''
  }));
}

export async function updateMusicState(req: Request, res: Response) {
  const body = req.body as MusicStateRequest;
  const rows = await listMusicLibrary();
  const meta = rows.find((item) => item.id === body.songId);
  const updatedAt = typeof body.updatedAt === 'string' ? body.updatedAt : new Date().toISOString();
  await saveMusicStateRecord(body.songId, body.playing, body.position, req.header('X-Device-Id') ?? 'unknown', updatedAt);
  const overview = await loadOverview();
  const updatedLogs = [`音乐状态更新：${meta ? meta.title : body.songId}`, ...overview.logs].slice(0, 8);
  await saveOverviewRecord({ logsJson: JSON.stringify(updatedLogs), lastSyncTime: new Date().toISOString() });
  broadcastEvent(createSyncEvent('music.stateChanged', { songId: body.songId, playing: body.playing ? 1 : 0, position: body.position }, req.header('X-Device-Id') ?? undefined, req.header('X-User-Id') ?? undefined, 'music', ['music', 'overview', 'log']));
  res.json(wrap({ version: Date.now(), musicState: { songId: body.songId, playing: body.playing, position: body.position, updatedAt } }));
}
