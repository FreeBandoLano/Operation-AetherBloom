@echo off
echo Installing Python dependencies...
pip install -r requirements.txt

echo Starting Flask server...
start python server_script.py

echo Opening AetherBloom website...
timeout /t 2
start "" "landing\index.html"

echo Done! 