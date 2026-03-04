@echo off
chcp 65001 >nul
echo ========================================
echo Database Initialization
echo ========================================
echo.
echo Please make sure MySQL is running!
echo.
echo Press any key to continue...
pause >nul
echo.
echo Initializing database...
echo.
mysql -u root -p < src\database\init.sql
echo.
if %errorlevel% equ 0 (
    echo Success! Database initialized.
) else (
    echo Failed! Please check:
    echo 1. MySQL is running
    echo 2. Password is correct
    echo 3. File path is correct
)
echo.
pause
