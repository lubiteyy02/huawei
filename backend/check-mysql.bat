@echo off
chcp 65001 >nul
echo ========================================
echo MySQL Environment Check
echo ========================================
echo.

echo [1] Checking MySQL command...
where mysql >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ MySQL command found in PATH
    echo.
    echo MySQL version:
    mysql --version
) else (
    echo ✗ MySQL command NOT found in PATH
    echo.
    echo Searching for MySQL installation...
    dir "C:\Program Files\MySQL" /s /b 2>nul | findstr mysql.exe
    if %errorlevel% neq 0 (
        echo ✗ MySQL not found in C:\Program Files\MySQL
    )
)

echo.
echo ========================================
echo [2] Checking MySQL service...
sc query MySQL80 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ MySQL80 service found
    sc query MySQL80 | findstr STATE
) else (
    echo ✗ MySQL80 service not found
    echo.
    echo Checking for other MySQL services...
    sc query type= service state= all | findstr /i "mysql"
)

echo.
echo ========================================
echo [3] Testing MySQL connection...
echo Attempting to connect to MySQL...
mysql -u root -e "SELECT VERSION();" 2>nul
if %errorlevel% equ 0 (
    echo ✓ MySQL connection successful
) else (
    echo ✗ MySQL connection failed
    echo Please check:
    echo   - MySQL service is running
    echo   - Root password is correct
)

echo.
echo ========================================
echo Check complete
echo ========================================
pause
