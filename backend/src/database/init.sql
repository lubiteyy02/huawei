-- 车载导航系统数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS car_navigation DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE car_navigation;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    phone VARCHAR(20) UNIQUE NOT NULL COMMENT '手机号',
    password VARCHAR(255) NOT NULL COMMENT '密码（加密）',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar VARCHAR(255) COMMENT '头像URL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 收藏地点表
CREATE TABLE IF NOT EXISTS favorites (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '收藏ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    name VARCHAR(100) NOT NULL COMMENT '地点名称',
    address VARCHAR(255) NOT NULL COMMENT '详细地址',
    latitude DECIMAL(10, 7) NOT NULL COMMENT '纬度',
    longitude DECIMAL(10, 7) NOT NULL COMMENT '经度',
    category VARCHAR(20) DEFAULT 'custom' COMMENT '分类：home-家, work-公司, custom-自定义',
    icon VARCHAR(50) COMMENT '图标',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_category (user_id, category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏地点表';

-- 导航历史表
CREATE TABLE IF NOT EXISTS navigation_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '历史ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    start_name VARCHAR(100) COMMENT '起点名称',
    start_address VARCHAR(255) COMMENT '起点地址',
    start_lat DECIMAL(10, 7) COMMENT '起点纬度',
    start_lng DECIMAL(10, 7) COMMENT '起点经度',
    end_name VARCHAR(100) NOT NULL COMMENT '终点名称',
    end_address VARCHAR(255) NOT NULL COMMENT '终点地址',
    end_lat DECIMAL(10, 7) NOT NULL COMMENT '终点纬度',
    end_lng DECIMAL(10, 7) NOT NULL COMMENT '终点经度',
    distance INT COMMENT '距离（米）',
    duration INT COMMENT '时长（秒）',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_created (user_id, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='导航历史表';

-- 行程记录表
CREATE TABLE IF NOT EXISTS trip_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '行程ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    start_time TIMESTAMP NOT NULL COMMENT '开始时间',
    end_time TIMESTAMP COMMENT '结束时间',
    total_distance INT COMMENT '总距离（米）',
    total_duration INT COMMENT '总时长（秒）',
    avg_speed DECIMAL(5, 2) COMMENT '平均速度（km/h）',
    max_speed DECIMAL(5, 2) COMMENT '最高速度（km/h）',
    trajectory TEXT COMMENT '轨迹数据（JSON格式）',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_start (user_id, start_time DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='行程记录表';

-- 路线方案表（保存用户规划的路线）
CREATE TABLE IF NOT EXISTS route_plans (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '路线ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    name VARCHAR(100) COMMENT '路线名称',
    start_name VARCHAR(100) NOT NULL COMMENT '起点名称',
    start_lat DECIMAL(10, 7) NOT NULL COMMENT '起点纬度',
    start_lng DECIMAL(10, 7) NOT NULL COMMENT '起点经度',
    end_name VARCHAR(100) NOT NULL COMMENT '终点名称',
    end_lat DECIMAL(10, 7) NOT NULL COMMENT '终点纬度',
    end_lng DECIMAL(10, 7) NOT NULL COMMENT '终点经度',
    waypoints TEXT COMMENT '途经点（JSON数组）',
    distance INT COMMENT '总距离（米）',
    duration INT COMMENT '预计时长（秒）',
    strategy TINYINT DEFAULT 0 COMMENT '策略：0-推荐 1-避免拥堵 2-避免收费 3-高速优先',
    polyline TEXT COMMENT '路线坐标串',
    steps TEXT COMMENT '导航步骤（JSON）',
    is_favorite BOOLEAN DEFAULT FALSE COMMENT '是否收藏',
    use_count INT DEFAULT 0 COMMENT '使用次数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_favorite (user_id, is_favorite),
    INDEX idx_user_created (user_id, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路线方案表';

-- 实时位置表（用于位置共享和协同导航）
CREATE TABLE IF NOT EXISTS user_locations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '位置ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    latitude DECIMAL(10, 7) NOT NULL COMMENT '纬度',
    longitude DECIMAL(10, 7) NOT NULL COMMENT '经度',
    accuracy DECIMAL(6, 2) COMMENT '精度（米）',
    speed DECIMAL(6, 2) COMMENT '速度（km/h）',
    heading DECIMAL(5, 2) COMMENT '方向（度）',
    location_type VARCHAR(20) DEFAULT 'ip' COMMENT '定位类型：gps, network, ip',
    is_sharing BOOLEAN DEFAULT FALSE COMMENT '是否共享位置',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sharing (is_sharing, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='实时位置表';

-- 位置共享关系表
CREATE TABLE IF NOT EXISTS location_shares (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '共享ID',
    sharer_id BIGINT NOT NULL COMMENT '分享者ID',
    viewer_id BIGINT NOT NULL COMMENT '查看者ID',
    expire_time TIMESTAMP COMMENT '过期时间',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (sharer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (viewer_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_share_view (sharer_id, viewer_id),
    INDEX idx_viewer_active (viewer_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='位置共享关系表';

-- 导航反馈表（用于收集用户反馈）
CREATE TABLE IF NOT EXISTS navigation_feedback (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '反馈ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    navigation_id BIGINT COMMENT '导航历史ID',
    rating TINYINT COMMENT '评分（1-5）',
    feedback_type VARCHAR(20) COMMENT '反馈类型：route-路线 traffic-路况 poi-地点',
    content TEXT COMMENT '反馈内容',
    location_lat DECIMAL(10, 7) COMMENT '反馈位置纬度',
    location_lng DECIMAL(10, 7) COMMENT '反馈位置经度',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (navigation_id) REFERENCES navigation_history(id) ON DELETE SET NULL,
    INDEX idx_user_created (user_id, created_at DESC),
    INDEX idx_type (feedback_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='导航反馈表';

-- 常用地点统计表（智能推荐）
CREATE TABLE IF NOT EXISTS frequent_locations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '统计ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    name VARCHAR(100) NOT NULL COMMENT '地点名称',
    address VARCHAR(255) COMMENT '地址',
    latitude DECIMAL(10, 7) NOT NULL COMMENT '纬度',
    longitude DECIMAL(10, 7) NOT NULL COMMENT '经度',
    visit_count INT DEFAULT 1 COMMENT '访问次数',
    last_visit TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '最后访问时间',
    time_pattern VARCHAR(50) COMMENT '时间规律（如：工作日早上）',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_location (user_id, latitude, longitude),
    INDEX idx_user_count (user_id, visit_count DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='常用地点统计表';

-- 搜索历史表
CREATE TABLE IF NOT EXISTS search_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '搜索ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    keyword VARCHAR(100) NOT NULL COMMENT '搜索关键词',
    result_count INT DEFAULT 0 COMMENT '结果数量',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_created (user_id, created_at DESC),
    INDEX idx_keyword (keyword)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='搜索历史表';

-- 插入测试数据（可选）
-- 密码为 123456 的bcrypt加密结果
INSERT INTO users (phone, password, nickname) VALUES 
('13800138000', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '测试用户1'),
('13800138001', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '测试用户2');

-- 插入测试收藏
INSERT INTO favorites (user_id, name, address, latitude, longitude, category) VALUES
(1, '家', '北京市海淀区中关村大街1号', 39.9042, 116.4074, 'home'),
(1, '公司', '北京市朝阳区建国门外大街1号', 39.9100, 116.4500, 'work'),
(1, '星巴克', '北京市海淀区中关村大街2号', 39.9050, 116.4080, 'custom');

COMMIT;
