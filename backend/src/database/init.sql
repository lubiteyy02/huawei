-- ============================================================
-- 业务表（users / favorites / navigation_history）
-- 使用 IF NOT EXISTS：已有数据保留，首次建库自动创建
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  phone VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  nickname VARCHAR(64) NOT NULL,
  avatar VARCHAR(512) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS favorites (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  name VARCHAR(128) NOT NULL,
  address VARCHAR(255) NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  category VARCHAR(32) NOT NULL DEFAULT 'custom',
  icon VARCHAR(255) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_favorites_user (user_id),
  INDEX idx_favorites_user_coord (user_id, latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS navigation_history (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  start_name VARCHAR(128) NOT NULL,
  start_address VARCHAR(255) NOT NULL,
  start_lat DOUBLE NOT NULL,
  start_lng DOUBLE NOT NULL,
  end_name VARCHAR(128) NOT NULL,
  end_address VARCHAR(255) NOT NULL,
  end_lat DOUBLE NOT NULL,
  end_lng DOUBLE NOT NULL,
  distance INT NOT NULL DEFAULT 0,
  duration INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_nav_history_user (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 协同模块表：每次初始化重建，只是演示数据
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS collaboration_sync_logs;
DROP TABLE IF EXISTS collaboration_continuation_tasks;
DROP TABLE IF EXISTS collaboration_music_state;
DROP TABLE IF EXISTS collaboration_music_library;
DROP TABLE IF EXISTS collaboration_message_threads;
DROP TABLE IF EXISTS collaboration_contacts;
DROP TABLE IF EXISTS collaboration_overview;
DROP TABLE IF EXISTS collaboration_active_devices;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE collaboration_overview (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  phone_name VARCHAR(128) NOT NULL,
  car_name VARCHAR(128) NOT NULL,
  sync_status VARCHAR(32) NOT NULL,
  last_sync_time DATETIME NOT NULL,
  unread_messages INT NOT NULL DEFAULT 0,
  contact_count INT NOT NULL DEFAULT 0,
  music_count INT NOT NULL DEFAULT 0,
  continuation_count INT NOT NULL DEFAULT 0,
  logs_json LONGTEXT NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_contacts (
  id BIGINT PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  phone VARCHAR(32) NOT NULL,
  tag VARCHAR(32) NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_message_threads (
  id BIGINT PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  preview VARCHAR(255) NOT NULL,
  time_text VARCHAR(32) NOT NULL,
  unread INT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_music_library (
  id BIGINT PRIMARY KEY,
  title VARCHAR(128) NOT NULL,
  artist VARCHAR(128) NOT NULL,
  progress INT NOT NULL DEFAULT 0,
  device VARCHAR(64) NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_music_state (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  song_id BIGINT NOT NULL,
  playing TINYINT(1) NOT NULL DEFAULT 0,
  position BIGINT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL,
  source_device VARCHAR(64) NOT NULL DEFAULT ''
);

CREATE TABLE collaboration_continuation_tasks (
  id BIGINT PRIMARY KEY,
  module_name VARCHAR(64) NOT NULL,
  title VARCHAR(128) NOT NULL,
  detail_text VARCHAR(255) NOT NULL,
  device_name VARCHAR(64) NOT NULL,
  completed TINYINT(1) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_sync_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  message_text VARCHAR(255) NOT NULL,
  source_label VARCHAR(64) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 在线设备表：WebSocket subscribe 时 upsert 一条，断开时标记 offline。
-- role 仅按 device_id 前缀推断（phone-* / car-*），用于前端区分本机/对端。
CREATE TABLE collaboration_active_devices (
  device_id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  role VARCHAR(16) NOT NULL DEFAULT 'phone',
  online TINYINT(1) NOT NULL DEFAULT 1,
  last_seen DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_active_user (user_id, online)
);

-- 协同模块大部分表不写种子数据，由用户真实操作产生。
-- 唯一例外：collaboration_music_library 写入 3 首本地真实可播放音乐
-- （对应 entry/src/main/resources/rawfile/sample_music_*.mp3，
--  与 RealAudioPlayerService.TRACK_TABLE 中的 id/title/artist 完全一致），
-- 这是项目自带的资源，不是假数据。
INSERT INTO collaboration_music_library (id, title, artist, progress, device) VALUES
(1, '发如雪', '周杰伦', 0, '离线音乐'),
(2, '听妈妈的话', '周杰伦', 0, '离线音乐'),
(3, '以父之名', '周杰伦', 0, '离线音乐');
