import logging
from flask import Flask, jsonify

app = Flask(__name__)

# Define the endpoint to send data to Flutter
@app.route('/fetchData', methods=['GET'])
def fetch_data():
    # Sample data response
    print("Request received from Flutter")  # Add this line to log the request
    sample_data = {"inhalerUseCount": 5, "timestamp": "2024-11-09", "notes": "Sample Note"}
    logging.info("Sending sample data to Flutter.")
    return jsonify(sample_data)


if __name__ == "__main__":
    # Set up logging to see server messages
    logging.basicConfig(level=logging.INFO)
    logging.info("Server started and awaiting Flutter requests.")
    
    # Start the Flask server on port 5000
    app.run(port=5000)
