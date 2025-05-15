import requests
import json

def test_notification():
    try:
        response = requests.post(
            'http://localhost:8080/notify',
            headers={'Content-Type': 'application/json'},
            json={
                'title': 'Test Notification',
                'message': 'This is a test notification from AetherBloom',
                'duration': 5
            }
        )
        print(f"Response status: {response.status_code}")
        print(f"Response body: {response.text}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    print("Sending test notification...")
    test_notification()
    print("Done!") 