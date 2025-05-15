@echo off
echo Installing Python dependencies...
cd server
pip install werkzeug==2.0.2 flask==2.0.1 flask-cors==3.0.10

echo Starting Flask server...
start python server_script.py

echo Opening AetherBloom website...
timeout /t 2
cd ..
start website\index.html

echo Starting Bluetooth sensor monitor...
rem Ensure we are in the project root where sensor_monitor.py is located
rem cd /d C:\FlutterProjects\Aetherbloom  <- This might be redundant if already in root after cd ..
start "Sensor Monitor" cmd /k python sensor_monitor.py

echo Opening Flutter app...
cd app
start "Flutter App" cmd /k flutter run

echo Done!
