import fs from 'fs';
import path from 'path';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

// 加载环境变量
dotenv.config();

async function main() {
  const dbHost = process.env.DB_HOST || 'localhost';
  const dbPort = Number(process.env.DB_PORT || 3306);
  const dbUser = process.env.DB_USER || 'root';
  const dbPassword = process.env.DB_PASSWORD || '';
  const dbName = process.env.DB_NAME || 'car_navigation';

  const sqlCandidates = [
    path.resolve(__dirname, 'init.sql'),
    path.resolve(process.cwd(), 'src/database/init.sql'),
    path.resolve(process.cwd(), 'backend/src/database/init.sql')
  ];

  const sqlPath = sqlCandidates.find((candidate) => fs.existsSync(candidate));

  if (!sqlPath) {
    console.error('❌ 找不到数据库初始化脚本，已尝试路径:', sqlCandidates);
    process.exit(1);
  }

  const sql = fs.readFileSync(sqlPath, 'utf8');

  const connection = await mysql.createConnection({
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: dbPassword,
    database: dbName,
    multipleStatements: true
  });

  try {
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\``);
    await connection.query(`USE \`${dbName}\``);
    await connection.query(sql);
    console.log('✅ 数据库初始化完成');
    console.log(`✅ 数据库名称: ${dbName}`);
  } catch (error) {
    console.error('❌ 数据库初始化失败:', error);
    process.exitCode = 1;
  } finally {
    await connection.end();
  }
}

main().catch((error) => {
  console.error('❌ 初始化脚本执行失败:', error);
  process.exit(1);
});
