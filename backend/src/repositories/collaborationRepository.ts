import { query } from '../config/database';

export interface CollaborationOverviewRecord {
  id: number;
  phoneName: string;
  carName: string;
  syncStatus: string;
  lastSyncTime: string;
  unreadMessages: number;
  contactCount: number;
  musicCount: number;
  continuationCount: number;
  logsJson: string;
}

export interface CollaborationContactRecord {
  id: number;
  name: string;
  phone: string;
  tag: string;
}

export interface CollaborationMessageThreadRecord {
  id: number;
  name: string;
  preview: string;
  timeText: string;
  unread: number;
}

export interface CollaborationMusicLibraryRecord {
  id: number;
  title: string;
  artist: string;
  progress: number;
  device: string;
}

export interface CollaborationMusicStateRecord {
  id: number;
  songId: number;
  playing: number;
  position: number;
  updatedAt: string;
  sourceDevice: string;
}

export interface CollaborationContinuationTaskRecord {
  id: number;
  moduleName: string;
  title: string;
  detailText: string;
  deviceName: string;
  completed: number;
}

export interface CollaborationSyncLogRecord {
  id: number;
  messageText: string;
  sourceLabel: string;
  createdAt: string;
}

export async function getOverviewRecord(): Promise<CollaborationOverviewRecord | null> {
  const rows = await query<CollaborationOverviewRecord[]>('SELECT * FROM collaboration_overview WHERE id = 1 LIMIT 1');
  return rows[0] ?? null;
}

export async function saveOverviewRecord(record: Partial<CollaborationOverviewRecord>): Promise<void> {
  await query(
    'UPDATE collaboration_overview SET phone_name = COALESCE(?, phone_name), car_name = COALESCE(?, car_name), sync_status = COALESCE(?, sync_status), last_sync_time = COALESCE(?, last_sync_time), unread_messages = COALESCE(?, unread_messages), contact_count = COALESCE(?, contact_count), music_count = COALESCE(?, music_count), continuation_count = COALESCE(?, continuation_count), logs_json = COALESCE(?, logs_json) WHERE id = 1',
    [
      record.phoneName ?? null,
      record.carName ?? null,
      record.syncStatus ?? null,
      record.lastSyncTime ?? null,
      record.unreadMessages ?? null,
      record.contactCount ?? null,
      record.musicCount ?? null,
      record.continuationCount ?? null,
      record.logsJson ?? null
    ]
  );
}

export async function listContacts(): Promise<CollaborationContactRecord[]> {
  return query<CollaborationContactRecord[]>('SELECT * FROM collaboration_contacts ORDER BY id ASC');
}

export async function updateContactTagById(id: number, tag: string): Promise<boolean> {
  const result = await query<{ affectedRows: number }>('UPDATE collaboration_contacts SET tag = ? WHERE id = ?', [tag, id]);
  return Array.isArray(result) ? true : true;
}

export async function listThreads(): Promise<CollaborationMessageThreadRecord[]> {
  return query<CollaborationMessageThreadRecord[]>('SELECT * FROM collaboration_message_threads ORDER BY id ASC');
}

export async function markThreadRead(threadId: number): Promise<boolean> {
  await query('UPDATE collaboration_message_threads SET unread = 0 WHERE id = ?', [threadId]);
  return true;
}

export async function listMusicLibrary(): Promise<CollaborationMusicLibraryRecord[]> {
  return query<CollaborationMusicLibraryRecord[]>('SELECT * FROM collaboration_music_library ORDER BY id ASC');
}

export async function getMusicStateRecord(): Promise<CollaborationMusicStateRecord | null> {
  const rows = await query<CollaborationMusicStateRecord[]>('SELECT * FROM collaboration_music_state ORDER BY id DESC LIMIT 1');
  return rows[0] ?? null;
}

export async function saveMusicStateRecord(songId: number, playing: boolean, position: number, sourceDevice: string, updatedAt: string): Promise<void> {
  await query('INSERT INTO collaboration_music_state (song_id, playing, position, updated_at, source_device) VALUES (?, ?, ?, ?, ?)', [songId, playing ? 1 : 0, position, updatedAt, sourceDevice]);
}

export async function listContinuationTasks(): Promise<CollaborationContinuationTaskRecord[]> {
  return query<CollaborationContinuationTaskRecord[]>('SELECT * FROM collaboration_continuation_tasks WHERE completed = 0 ORDER BY id ASC');
}

export async function completeContinuationTask(taskId: number): Promise<boolean> {
  await query('UPDATE collaboration_continuation_tasks SET completed = 1 WHERE id = ?', [taskId]);
  return true;
}

export async function insertSyncLog(messageText: string, sourceLabel: string): Promise<void> {
  await query('INSERT INTO collaboration_sync_logs (message_text, source_label) VALUES (?, ?)', [messageText, sourceLabel]);
}

export async function recentLogs(limit: number): Promise<CollaborationSyncLogRecord[]> {
  const safeLimit = Number(limit) || 10;
  return query<CollaborationSyncLogRecord[]>(`SELECT * FROM collaboration_sync_logs ORDER BY id DESC LIMIT ${safeLimit}`, []);
}
