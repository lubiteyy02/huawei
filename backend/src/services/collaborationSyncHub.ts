import { WebSocketServer, WebSocket } from 'ws';
import { upsertActiveDevice, markDeviceOffline } from '../repositories/collaborationRepository';

export type CollaborationSyncEventType = 'contact.updated' | 'message.read' | 'message.created' | 'music.stateChanged' | 'music.handover' | 'continuation.resumed' | 'navigation.handover' | 'overview.refreshed' | 'device.online' | 'device.offline';

export interface CollaborationSyncEvent {
  type: CollaborationSyncEventType;
  sourceDeviceId?: string;
  userId?: string;
  payload: Record<string, string | number | boolean | null>;
  timestamp: string;
  scope: 'overview' | 'contacts' | 'messages' | 'music' | 'continuation' | 'log';
  refreshTargets: Array<'overview' | 'contacts' | 'messages' | 'music' | 'continuation' | 'log'>;
}

interface CollaborationSocketMessage {
  type: 'subscribe' | 'sync';
  userId?: string;
  deviceId?: string;
  event?: CollaborationSyncEvent;
}

const subscribedClients = new Map<WebSocket, { userId: string; deviceId: string }>();
let wsServer: WebSocketServer | null = null;

function safeParse(value: string): CollaborationSocketMessage | null {
  try {
    return JSON.parse(value) as CollaborationSocketMessage;
  } catch {
    return null;
  }
}

function send(socket: WebSocket, data: unknown): void {
  if (socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(data));
  }
}

export function initializeCollaborationSyncHub(server: import('http').Server): void {
  if (wsServer) {
    return;
  }

  wsServer = new WebSocketServer({ server, path: '/api/v1/sync/ws' });
  wsServer.on('connection', (socket) => {
    send(socket, { type: 'connected', timestamp: new Date().toISOString() });

    socket.on('message', (raw) => {
      const message = safeParse(raw.toString());
      if (!message) {
        send(socket, { type: 'error', message: 'invalid message' });
        return;
      }

      if (message.type === 'subscribe') {
        const userId = message.userId ?? 'default-user';
        const deviceId = message.deviceId ?? 'unknown-device';
        subscribedClients.set(socket, { userId, deviceId });
        send(socket, { type: 'subscribed', userId, deviceId, timestamp: new Date().toISOString() });
        // 设备上线：DB upsert + 广播给同 user 的其他在线设备
        upsertActiveDevice(deviceId, userId)
          .then((record) => {
            broadcastEvent(createSyncEvent(
              'device.online',
              { deviceId, role: record.role, userId },
              deviceId,
              userId,
              'overview',
              ['overview']
            ));
          })
          .catch((err) => console.error('[SyncHub] upsertActiveDevice failed', err));
        return;
      }

      if (message.type === 'sync' && message.event) {
        broadcastEvent(message.event);
      }
    });

    socket.on('close', () => {
      const info = subscribedClients.get(socket);
      subscribedClients.delete(socket);
      if (!info) return;
      // 设备下线：DB 标记 + 广播
      markDeviceOffline(info.deviceId)
        .then(() => {
          broadcastEvent(createSyncEvent(
            'device.offline',
            { deviceId: info.deviceId, userId: info.userId },
            info.deviceId,
            info.userId,
            'overview',
            ['overview']
          ));
        })
        .catch((err) => console.error('[SyncHub] markDeviceOffline failed', err));
    });
  });
}

export function broadcastEvent(event: CollaborationSyncEvent): void {
  // === PERF TEST LOG (论文测试章用，定稿前删除) ===
  console.log('PERF_HUB ' + JSON.stringify({
    side: 'hub',
    ts: Date.now(),
    type: event.type,
    src: (event as any).sourceDeviceId,
    evtId: (event as any).eventId
  }));
  // === END PERF TEST LOG ===

  const payload = {
    type: 'sync-event',
    event
  };

  subscribedClients.forEach((clientInfo, socket) => {
    if (socket.readyState === WebSocket.OPEN) {
      send(socket, {
        ...payload,
        targetUserId: clientInfo.userId,
        targetDeviceId: clientInfo.deviceId
      });
    }
  });
}

export function createSyncEvent(
  type: CollaborationSyncEventType,
  payload: Record<string, string | number | boolean | null>,
  sourceDeviceId?: string,
  userId?: string,
  scope: CollaborationSyncEvent['scope'] = 'overview',
  refreshTargets: CollaborationSyncEvent['refreshTargets'] = ['overview']
): CollaborationSyncEvent {
  return {
    type,
    payload,
    sourceDeviceId,
    userId,
    timestamp: new Date().toISOString(),
    scope,
    refreshTargets
  };
}
