@echo off
chcp 65001 >nul
echo ========================================
echo 测试后端API详细信息
echo ========================================
echo.

echo [1] 测试健康检查 (localhost)
curl -v http://localhost:3000/health
echo.
echo.

echo [2] 测试健康检查 (192.168.6.191)
curl -v http://192.168.6.191:3000/health
echo.
echo.

echo [3] 测试注册API (localhost)
curl -v -X POST http://localhost:3000/api/v1/auth/register -H "Content-Type: application/json" -d "{\"phone\":\"13797427641\",\"password\":\"123456\",\"nickname\":\"测试\"}"
echo.
echo.

echo [4] 测试注册API (192.168.6.191)
curl -v -X POST http://192.168.6.191:3000/api/v1/auth/register -H "Content-Type: application/json" -d "{\"phone\":\"13797427641\",\"password\":\"123456\",\"nickname\":\"测试\"}"
echo.
echo.

echo ========================================
echo 测试完成
echo ========================================
pause
