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
