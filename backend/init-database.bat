@echo off
echo ========================================
echo 车载导航系统 - 数据库初始化
echo ========================================
echo.

echo 请确保MySQL已经启动！
echo.

echo 方式1: 使用MySQL命令行
echo ----------------------------------------
echo 命令: mysql -u root -p ^< src/database/init.sql
echo.
echo 执行步骤:
echo 1. 输入MySQL root密码
echo 2. 等待数据库创建完成
echo.

echo 方式2: 手动执行（推荐）
echo ----------------------------------------
echo 1. 打开MySQL客户端（如Navicat、DBeaver、MySQL Workbench）
echo 2. 连接到MySQL服务器
echo 3. 打开文件: src/database/init.sql
echo 4. 执行SQL脚本
echo.

echo ========================================
echo 按任意键尝试使用命令行方式...
pause >nul

echo.
echo 正在执行数据库初始化...
mysql -u root -p < src\database\init.sql

if %errorlevel% equ 0 (
    echo.
    echo ✅ 数据库初始化成功！
) else (
    echo.
    echo ❌ 数据库初始化失败！
    echo 请检查:
    echo 1. MySQL是否已启动
    echo 2. root密码是否正确
    echo 3. 或使用方式2手动执行
)

echo.
pause
