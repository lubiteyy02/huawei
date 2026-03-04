/**
 * 数据库初始化脚本
 * 使用Node.js直接执行SQL文件
 */

const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function initDatabase() {
  console.log('========================================');
  console.log('数据库初始化开始');
  console.log('========================================\n');

  let connection;

  try {
    // 读取SQL文件
    const sqlFile = path.join(__dirname, 'src', 'database', 'init.sql');
    console.log('读取SQL文件:', sqlFile);
    
    if (!fs.existsSync(sqlFile)) {
      throw new Error('SQL文件不存在: ' + sqlFile);
    }
    
    const sqlContent = fs.readFileSync(sqlFile, 'utf8');
    console.log('✓ SQL文件读取成功\n');

    // 连接MySQL（不指定数据库）
    console.log('连接MySQL服务器...');
    console.log('Host:', process.env.DB_HOST || 'localhost');
    console.log('Port:', process.env.DB_PORT || 3306);
    console.log('User:', process.env.DB_USER || 'root');
    
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true
    });
    
    console.log('✓ MySQL连接成功\n');

    // 执行SQL
    console.log('执行SQL脚本...');
    await connection.query(sqlContent);
    console.log('✓ SQL执行成功\n');

    // 验证数据库
    console.log('验证数据库...');
    const [databases] = await connection.query('SHOW DATABASES LIKE "car_navigation"');
    
    if (databases.length > 0) {
      console.log('✓ 数据库 car_navigation 创建成功\n');
      
      // 切换到新数据库
      await connection.query('USE car_navigation');
      
      // 查看表
      const [tables] = await connection.query('SHOW TABLES');
      console.log('创建的表:');
      tables.forEach((table, index) => {
        const tableName = Object.values(table)[0];
        console.log(`  ${index + 1}. ${tableName}`);
      });
      console.log(`\n总共创建了 ${tables.length} 个表\n`);
    }

    console.log('========================================');
    console.log('✅ 数据库初始化完成！');
    console.log('========================================\n');

  } catch (error) {
    console.error('\n========================================');
    console.error('❌ 数据库初始化失败！');
    console.error('========================================\n');
    console.error('错误信息:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.error('\n可能的原因:');
      console.error('1. MySQL服务未启动');
      console.error('2. 端口号不正确');
      console.error('3. 主机地址不正确');
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('\n可能的原因:');
      console.error('1. 用户名或密码错误');
      console.error('2. 用户没有权限');
      console.error('\n请检查 .env 文件中的配置:');
      console.error('  DB_USER=root');
      console.error('  DB_PASSWORD=你的密码');
    }
    
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// 运行初始化
initDatabase();
