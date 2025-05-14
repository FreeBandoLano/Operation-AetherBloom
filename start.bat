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

echo Opening Flutter app...
cd app
start cmd /k flutter run

echo Done!
