import { WebSocketServer, WebSocket } from 'ws';

export type CollaborationSyncEventType = 'contact.updated' | 'message.read' | 'music.stateChanged' | 'continuation.resumed' | 'overview.refreshed';

export interface CollaborationSyncEvent {
  type: CollaborationSyncEventType;
  sourceDeviceId?: string;
  userId?: string;
  payload: Record<string, string | number | boolean | null>;
  timestamp: string;
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
        return;
      }

      if (message.type === 'sync' && message.event) {
        broadcastEvent(message.event);
      }
    });

    socket.on('close', () => {
      subscribedClients.delete(socket);
    });
  });
}

export function broadcastEvent(event: CollaborationSyncEvent): void {
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
  userId?: string
): CollaborationSyncEvent {
  return {
    type,
    payload,
    sourceDeviceId,
    userId,
    timestamp: new Date().toISOString()
  };
}
