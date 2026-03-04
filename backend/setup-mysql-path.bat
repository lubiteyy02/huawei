@echo off
chcp 65001 >nul
echo ========================================
echo MySQL Environment Variable Setup
echo ========================================
echo.
echo This script will add MySQL to your PATH
echo Location: C:\Program Files\MySQL\MySQL Server 8.0\bin
echo.
echo NOTE: You need to run this as Administrator!
echo.
pause

echo.
echo Adding MySQL to system PATH...
setx PATH "%PATH%;C:\Program Files\MySQL\MySQL Server 8.0\bin" /M

if %errorlevel% equ 0 (
    echo.
    echo ✓ MySQL path added successfully!
    echo.
    echo IMPORTANT: You MUST close and reopen your command prompt
    echo for the changes to take effect.
    echo.
) else (
    echo.
    echo ✗ Failed to add MySQL to PATH
    echo.
    echo Please run this script as Administrator:
    echo 1. Right-click on setup-mysql-path.bat
    echo 2. Select "Run as administrator"
    echo.
)

echo ========================================
pause
