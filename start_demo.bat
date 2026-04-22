@echo off
echo Starting OmniTriage demo environment...
start "Firebase Emulator" cmd /k "cd C:\omnitriage && firebase emulators:start --only functions"
timeout /t 8 /nobreak
start "ngrok tunnel" cmd /k "cd C:\omnitriage && ngrok http 5001"
echo.
echo Both windows starting. Wait 15 seconds, then:
echo 1. Copy the ngrok HTTPS URL from the ngrok window
echo 2. Update DISPATCH_FUNCTION_URL in dashboard\lib\screens\coordinator_dashboard.dart
echo 3. Run: cd dashboard && flutter build web --release && cd .. && firebase deploy --only hosting
echo.
pause