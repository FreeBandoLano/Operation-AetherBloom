from win10toast import ToastNotifier
import time

def test_notification():
    print("Initializing ToastNotifier...")
    toaster = ToastNotifier()
    
    print("Showing toast notification...")
    toaster.show_toast(
        "Test Notification",
        "This is a test message. If you see this, notifications are working!",
        duration=5,
        threaded=False  # Use non-threaded to ensure it shows before script ends
    )
    print("Toast notification should have been shown.")
    
    print("Done!")

if __name__ == "__main__":
    test_notification() 