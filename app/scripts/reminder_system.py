# reminder_system.py

import time
from plyer import notification
from data_logger import log_data  # Import the logging function

def send_reminder(message="Time to take your inhaler!", interval=3600):
    """Send a reminder notification and log each reminder in real time."""
    while True:
        # Display notification
        notification.notify(
            title="Inhaler Reminder",
            message=message,
            timeout=10  # Notification stays visible for 10 seconds
        )
        print(f"Reminder sent: {message}")
        
        # Log the reminder with a timestamp
        log_data(entry_type="Reminder", message=message)
        
        # Wait for the specified interval before sending the next reminder
        time.sleep(interval)

# Usage: Run this function to start reminders with logging
send_reminder()  # This will send reminders every hour (3600 seconds)
