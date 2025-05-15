import serial
import time

PORT = 'COM5'  # Use the port from ble-serial
BAUDRATE = 9600  # Must match your AT+BAUD setting

AT_COMMANDS = [
    "AT+BAUD?",
    "AT+NOTI?",
    "AT+ROLE?",
    "AT+RESET"
]

def send_command(ser, command):
    ser.write(f"{command}\r\n".encode())
    time.sleep(0.5)
    response = ser.read_all().decode().strip()
    return response

with serial.Serial(PORT, BAUDRATE, timeout=1) as ser:
    print(f"Connected to {PORT}")
    
    for cmd in AT_COMMANDS:
        print(f"Sending: {cmd}")
        response = send_command(ser, cmd)
        print(f"Response: {response}")
        time.sleep(1) 