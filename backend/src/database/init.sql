SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS collaboration_sync_logs;
DROP TABLE IF EXISTS collaboration_continuation_tasks;
DROP TABLE IF EXISTS collaboration_music_state;
DROP TABLE IF EXISTS collaboration_music_library;
DROP TABLE IF EXISTS collaboration_message_threads;
DROP TABLE IF EXISTS collaboration_contacts;
DROP TABLE IF EXISTS collaboration_overview;

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

INSERT INTO collaboration_overview (id, phone_name, car_name, sync_status, last_sync_time, unread_messages, contact_count, music_count, continuation_count, logs_json)
VALUES (
  1,
  'Harmony Phone',
  'Harmony Car',
  '已连接',
  NOW(),
  3,
  128,
  56,
  2,
  '["联系人：已同步 128 条","短信：已同步最近 20 条会话","音乐：已续接播放《七里香》","应用续接：导航任务已同步到车机"]'
);

INSERT INTO collaboration_contacts (id, name, phone, tag) VALUES
(1, '李明', '138-0000-0001', '常用'),
(2, '王婷', '138-0000-0002', '最近'),
(3, '张伟', '138-0000-0003', '收藏');

INSERT INTO collaboration_message_threads (id, name, preview, time_text, unread) VALUES
(1, '妈妈', '路上注意安全，到家告诉我', '09:12', 1),
(2, '同事-小周', '会议资料已经发到群里了', '08:40', 0),
(3, '物业', '明天早上停水，请提前储水', '昨天', 2);

INSERT INTO collaboration_music_library (id, title, artist, progress, device) VALUES
(1, '七里香', '周杰伦', 64, '手机正在播放'),
(2, '稻香', '周杰伦', 22, '车机可续接'),
(3, '晴天', '周杰伦', 89, '最近播放');

INSERT INTO collaboration_music_state (song_id, playing, position, updated_at, source_device)
VALUES (1, 1, 68000, NOW(), '手机');

INSERT INTO collaboration_continuation_tasks (id, module_name, title, detail_text, device_name, completed) VALUES
(1, '导航', '去公司', '已在手机上规划路线', '手机', 0),
(2, '音乐', '七里香', '播放进度 01:08', '手机', 0);
