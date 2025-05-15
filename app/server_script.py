import logging
from flask import Flask, jsonify, request
from flask_cors import CORS  # Import CORS module
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# In-memory storage for demo purposes
usage_data = {
    "inhalerUseCount": 0,
    "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "notes": "No usage recorded yet"
}

# Define the endpoint to send data to Flutter
@app.route('/fetchData', methods=['GET'])
def fetch_data():
    """Endpoint to retrieve the current usage data"""
    logging.info("Data requested by client")
    return jsonify(usage_data)

@app.route('/updateData', methods=['POST'])
def update_data():
    """Endpoint to update usage data from the Flutter app"""
    global usage_data
    try:
        new_data = request.json
        logging.info(f"Received new data: {new_data}")
        
        # Update our stored data
        if 'inhalerUseCount' in new_data:
            usage_data['inhalerUseCount'] = new_data['inhalerUseCount']
        if 'notes' in new_data:
            usage_data['notes'] = new_data['notes']
        
        # Always update timestamp on new data
        usage_data['timestamp'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        return jsonify({"status": "success", "message": "Data updated"})
    except Exception as e:
        logging.error(f"Error updating data: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 400

if __name__ == "__main__":
    # Set up logging to see server messages
    logging.basicConfig(level=logging.INFO)
    logging.info("Server started with live data capability")
    
    # Start the Flask server on port 5000
    app.run(port=5000, debug=True)
