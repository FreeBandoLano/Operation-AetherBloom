@echo off
echo Installing Python dependencies...
pip install -r requirements.txt

echo Starting Python notification server...
start python windows_notifications.py

echo Starting Flutter app...
flutter run

echo Done! 