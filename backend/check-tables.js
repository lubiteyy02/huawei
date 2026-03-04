// 检查数据库表是否存在
const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkTables() {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'car_navigation'
    });

    console.log('✅ 数据库连接成功\n');

    // 检查所有表
    const [tables] = await connection.query('SHOW TABLES');
    console.log('📋 数据库中的表:');
    tables.forEach((row, index) => {
      const tableName = Object.values(row)[0];
      console.log(`${index + 1}. ${tableName}`);
    });

    // 检查 navigation_history 表结构
    console.log('\n📊 navigation_history 表结构:');
    const [columns] = await connection.query('DESCRIBE navigation_history');
    columns.forEach(col => {
      console.log(`  - ${col.Field} (${col.Type})`);
    });

    // 检查记录数
    const [count] = await connection.query('SELECT COUNT(*) as count FROM navigation_history');
    console.log(`\n📈 navigation_history 表记录数: ${count[0].count}`);

    await connection.end();
    console.log('\n✅ 检查完成');
  } catch (error) {
    console.error('❌ 错误:', error.message);
    if (error.code === 'ER_NO_SUCH_TABLE') {
      console.log('\n⚠️  表不存在！请运行数据库初始化脚本:');
      console.log('   mysql -u root -p < src/database/init.sql');
    }
  }
}

checkTables();
