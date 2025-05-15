import sys
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import datetime
import threading
import time
from typing import Dict, List
import logging
import win32api
import win32con
import win32gui

# Set up logging
logging.basicConfig(level=logging.INFO,
                   format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WindowsBalloonTip:
    def __init__(self, title, msg):
        message_map = {
            win32con.WM_DESTROY: self.OnDestroy,
        }
        # Register the Window class
        wc = win32gui.WNDCLASS()
        hinst = wc.hInstance = win32api.GetModuleHandle(None)
        wc.lpszClassName = "PythonTaskbar"
        wc.lpfnWndProc = message_map
        classAtom = win32gui.RegisterClass(wc)
        # Create the Window
        style = win32con.WS_OVERLAPPED | win32con.WS_SYSMENU
        self.hwnd = win32gui.CreateWindow(classAtom, "Taskbar", style,
                                          0, 0, win32con.CW_USEDEFAULT, win32con.CW_USEDEFAULT,
                                          0, 0, hinst, None)
        win32gui.UpdateWindow(self.hwnd)
        icon_flags = win32con.LR_LOADFROMFILE | win32con.LR_DEFAULTSIZE
        try:
            hicon = win32gui.LoadImage(hinst, "python.ico", win32con.IMAGE_ICON, 0, 0, icon_flags)
        except:
            hicon = win32gui.LoadIcon(0, win32con.IDI_APPLICATION)
        flags = win32gui.NIF_ICON | win32gui.NIF_MESSAGE | win32gui.NIF_TIP
        nid = (self.hwnd, 0, flags, win32con.WM_USER+20, hicon, "Aetherbloom Notification")
        win32gui.Shell_NotifyIcon(win32gui.NIM_ADD, nid)
        win32gui.Shell_NotifyIcon(win32gui.NIM_MODIFY,
                             (self.hwnd, 0, win32gui.NIF_INFO, win32con.WM_USER+20,
                              hicon, "Balloon  tooltip", msg, 200, title))
        
    def OnDestroy(self, hwnd, msg, wparam, lparam):
        win32gui.Shell_NotifyIcon(win32gui.NIM_DELETE, (self.hwnd, 0))
        win32gui.PostQuitMessage(0)

class NotificationManager:
    def __init__(self):
        self.scheduled_reminders: Dict[str, Dict] = {}
        self.start_scheduler()
        logger.info("NotificationManager initialized")

    def show_notification(self, title: str, message: str, duration: int = 5) -> bool:
        try:
            logger.info(f"Showing notification - Title: {title}, Message: {message}")
            # Use the working WindowsBalloonTip method
            WindowsBalloonTip(title, message)
            return True
        except Exception as e:
            logger.error(f"Error showing notification: {e}")
            return False

    def schedule_reminder(self, reminder_id: str, title: str, message: str, time_str: str, weekdays: List[int]) -> bool:
        try:
            logger.info(f"Scheduling reminder - ID: {reminder_id}, Title: {title}, Time: {time_str}, Weekdays: {weekdays}")
            
            # Show immediate confirmation
            self.show_notification(
                "Reminder Set",
                f"Reminder '{title}' scheduled for {time_str}"
            )
            
            self.scheduled_reminders[reminder_id] = {
                'title': title,
                'message': message,
                'time': time_str,
                'weekdays': weekdays
            }
            return True
        except Exception as e:
            logger.error(f"Error scheduling reminder: {e}")
            return False

    def cancel_reminder(self, reminder_id: str) -> bool:
        try:
            if reminder_id in self.scheduled_reminders:
                reminder = self.scheduled_reminders[reminder_id]
                logger.info(f"Cancelling reminder - ID: {reminder_id}, Title: {reminder['title']}")
                del self.scheduled_reminders[reminder_id]
                self.show_notification(
                    "Reminder Cancelled",
                    f"Reminder '{reminder['title']}' has been cancelled"
                )
            return True
        except Exception as e:
            logger.error(f"Error cancelling reminder: {e}")
            return False

    def start_scheduler(self):
        def check_reminders():
            while True:
                try:
                    now = datetime.datetime.now()
                    current_time = now.strftime("%H:%M")
                    current_weekday = now.weekday()

                    logger.debug(f"Checking reminders at {current_time} on weekday {current_weekday}")

                    for reminder_id, reminder in list(self.scheduled_reminders.items()):
                        try:
                            logger.debug(f"Checking reminder {reminder_id}: time={reminder['time']}, weekdays={reminder['weekdays']}")
                            
                            if (current_time == reminder['time'] and 
                                current_weekday in reminder['weekdays']):
                                logger.info(f"Triggering reminder: {reminder['title']} at {current_time}")
                                self.show_notification(
                                    reminder['title'],
                                    reminder['message']
                                )
                        except Exception as e:
                            logger.error(f"Error processing reminder {reminder_id}: {e}")
                    
                    # Sleep until the next minute
                    sleep_time = 60 - datetime.datetime.now().second
                    time.sleep(sleep_time)
                except Exception as e:
                    logger.error(f"Error in reminder checker: {e}")
                    time.sleep(60)  # Sleep for a minute if there's an error

        scheduler_thread = threading.Thread(target=check_reminders, daemon=True)
        scheduler_thread.start()
        logger.info("Reminder scheduler started")

class NotificationHandler(BaseHTTPRequestHandler):
    notification_manager = NotificationManager()

    def _send_response(self, status_code: int, message: str):
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Accept')
        self.end_headers()
        response_data = {'message': message}
        self.wfile.write(json.dumps(response_data).encode())

    def do_POST(self):
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                print(f"Raw request data: {post_data}")
                try:
                    post_data = json.loads(post_data)
                    print(f"Parsed request data: {post_data}")
                except json.JSONDecodeError as e:
                    print(f"Failed to parse JSON: {e}")
                    self._send_response(400, f'Invalid JSON format: {str(e)}')
                    return
            else:
                post_data = {}
            
            print(f"Received request to {self.path} with data: {post_data}")
            print(f"Request headers: {self.headers}")

            if self.path == '/notify':
                success = self.notification_manager.show_notification(
                    post_data.get('title', 'Notification'),
                    post_data.get('message', ''),
                    post_data.get('duration', 5)
                )
                self._send_response(200 if success else 500, 
                                'Notification sent' if success else 'Failed to send notification')

            elif self.path == '/schedule':
                # Extract reminder data from either format
                reminder = post_data.get('reminder', post_data)
                print(f"Processing reminder: {reminder}")
                
                # Handle 'message' or 'description' field
                message = reminder.get('description', reminder.get('message', ''))
                
                success = self.notification_manager.schedule_reminder(
                    reminder['id'],
                    reminder['title'],
                    message,
                    reminder['time'],
                    reminder.get('weekdays', [])
                )
                self._send_response(200 if success else 500,
                                'Reminder scheduled' if success else 'Failed to schedule reminder')

            elif self.path == '/cancel':
                success = self.notification_manager.cancel_reminder(
                    post_data.get('id', post_data.get('reminder_id', ''))
                )
                self._send_response(200 if success else 500,
                                'Reminder cancelled' if success else 'Failed to cancel reminder')
            else:
                self._send_response(404, 'Not found')
        except Exception as e:
            print(f"Error processing request: {str(e)}")
            import traceback
            traceback.print_exc()
            self._send_response(500, f'Internal server error: {str(e)}')

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Accept')
        self.end_headers()

def run_server(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, NotificationHandler)
    print(f"Starting notification server on port {port}...")
    print("Server is ready to handle notifications")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server gracefully...")
        httpd.server_close()
        print("Server shutdown complete")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    else:
        port = 8080
    try:
        run_server(port)
    except KeyboardInterrupt:
        print("\nServer process terminated by user")
        sys.exit(0) 