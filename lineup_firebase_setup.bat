@echo off
cd /d "C:\Users\aarav\Documents\LineUP"

echo ================================================
echo  Lineup - Firebase setup
echo ================================================
echo.

echo [1/4] Checking for Firebase CLI...
where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo Firebase CLI not found. Installing via npm (this can take a minute)...
    call npm install -g firebase-tools
) else (
    echo Firebase CLI already installed.
)
echo.

echo [2/4] Installing/updating FlutterFire CLI...
call dart pub global activate flutterfire_cli
echo.
echo NOTE: if the next steps say "flutterfire is not recognized", it means
echo the Dart global bin folder isn't on your PATH yet. The message above
echo from "dart pub global activate" tells you the exact folder to add
echo (usually C:\Users\aarav\AppData\Local\Pub\Cache\bin). Add it to PATH,
echo close this window, and re-run this script.
echo.

echo [3/4] Logging into Firebase...
echo A browser window will open - sign in with lalitha.a.m90@gmail.com
echo (the account that owns the "lineup" Firebase project).
call firebase login
echo.

echo [4/4] Fetching Flutter packages and configuring Firebase...
call flutter pub get
echo.
echo When prompted below:
echo   - Select Firebase project:  lineup
echo   - Platforms: press SPACE on android, ios, web, then ENTER
call flutterfire configure --project=lineup --platforms=android,ios,web

echo.
echo ================================================
echo  Done. Check that lib\firebase_options.dart now exists.
echo ================================================
echo Press any key to close this window.
pause >nul
