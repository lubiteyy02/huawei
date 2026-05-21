# 附录B 数据库表结构

> 以下 11 张表均采用 InnoDB 存储引擎、utf8mb4 字符集。套入 Word 时按三线表格式排版。

---

## 表B-1 用户表（users）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 用户主键 |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | 手机号 |
| password_hash | VARCHAR(255) | NOT NULL | 加盐哈希后的密码 |
| nickname | VARCHAR(50) | | 昵称 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 注册时间 |

---

## 表B-2 收藏地点表（favorite_places）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| name | VARCHAR(128) | NOT NULL | 地点名称 |
| address | VARCHAR(256) | | 地点地址 |
| longitude | DOUBLE | | 经度 |
| latitude | DOUBLE | | 纬度 |
| icon | VARCHAR(32) | | 自定义图标 |
| tag | VARCHAR(32) | | 分类标签 |

---

## 表B-3 导航历史表（navigation_history）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| dest_name | VARCHAR(128) | NOT NULL | 目的地名称 |
| dest_lng | DOUBLE | | 目的地经度 |
| dest_lat | DOUBLE | | 目的地纬度 |
| distance | VARCHAR(32) | | 路径距离 |
| duration | VARCHAR(32) | | 预估时长 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |

---

## 表B-4 协同总览表（collaboration_overview）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| phone_status | TINYINT | DEFAULT 0 | 手机端在线状态 |
| car_status | TINYINT | DEFAULT 0 | 车机端在线状态 |
| last_sync_time | VARCHAR(32) | | 最近同步时间 |
| unread_messages | INT | DEFAULT 0 | 未读消息数 |
| contact_count | INT | DEFAULT 0 | 联系人数 |
| music_count | INT | DEFAULT 0 | 音乐曲目数 |
| continuation_count | INT | DEFAULT 0 | 续接任务数 |
| sync_logs_json | JSON | | 最近同步日志摘要 |

---

## 表B-5 协同联系人表（collaboration_contacts）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| name | VARCHAR(50) | NOT NULL | 联系人姓名 |
| phone | VARCHAR(20) | | 联系电话 |
| tag | VARCHAR(32) | | 标签（家人/同事等）|

---

## 表B-6 协同短信会话表（collaboration_messages）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| contact_name | VARCHAR(50) | NOT NULL | 对端名称 |
| preview | VARCHAR(256) | | 最近一条预览 |
| time_text | VARCHAR(32) | | 时间文本 |
| unread_count | INT | DEFAULT 0 | 未读数 |

---

## 表B-7 协同音乐曲目表（collaboration_music_tracks）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| title | VARCHAR(64) | NOT NULL | 曲目名 |
| artist | VARCHAR(64) | | 艺术家 |
| progress_ms | INT | DEFAULT 0 | 当前进度（毫秒）|
| source | VARCHAR(64) | | 资源来源 |

---

## 表B-8 协同音乐播放状态表（collaboration_playback_state）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| track_id | INT | FOREIGN KEY → collaboration_music_tracks.id | 曲目标识 |
| is_playing | TINYINT | DEFAULT 0 | 是否正在播放 |
| position_ms | INT | DEFAULT 0 | 当前位置（毫秒）|
| updated_at | DATETIME | | 状态更新时间 |
| source_device | VARCHAR(64) | | 状态来源设备 |

---

## 表B-9 协同续接任务表（collaboration_continuation_tasks）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| type | ENUM('music','navigation') | NOT NULL | 续接类型 |
| source_device | VARCHAR(64) | | 发起设备 |
| target_device | VARCHAR(64) | | 目标设备 |
| payload | JSON | | 续接载荷 |
| status | TINYINT | DEFAULT 0 | 任务状态 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |

---

## 表B-10 同步日志表（sync_logs）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| event_type | VARCHAR(40) | NOT NULL | 事件类型 |
| content | VARCHAR(256) | | 日志内容 |
| source | VARCHAR(64) | | 来源标识 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |

---

## 表B-11 协同在线设备表（collaboration_active_devices）

| 字段名 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 主键 |
| user_id | INT | FOREIGN KEY → users.id | 所属用户 |
| device_id | VARCHAR(64) | NOT NULL | 设备标识 |
| device_role | ENUM('phone','car') | NOT NULL | 设备角色 |
| online | TINYINT | DEFAULT 0 | 是否在线 |
| last_heartbeat | DATETIME | | 最近心跳时间 |
