import asyncio
import sys
from bleak import BleakClient

ADDRESS = "04:A3:16:A8:94:D2"
UART_TX_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"

# Required configuration commands for BT05
AT_COMMANDS = [
    b"AT+BAUD4\r\n",    # Set baud rate to 9600
    b"AT+NOTI1\r\n",    # Enable notifications
    b"AT+ROLE0\r\n",    # Set to peripheral mode
    b"AT+RESET\r\n"     # Reboot module
]

async def configure_device():
    async with BleakClient(ADDRESS) as client:
        print(f"Connected to {ADDRESS}")
        
        # Send configuration commands
        for cmd in AT_COMMANDS:
            print(f"Sending: {cmd.decode().strip()}")
            await client.write_gatt_char(UART_TX_UUID, cmd)
            await asyncio.sleep(1)  # Wait for response
            
        print("Configuration complete. Monitoring for responses...")
        
        # Monitor for 10 seconds
        await asyncio.sleep(10)

if __name__ == "__main__":
    try:
        asyncio.run(configure_device())
    except Exception as e:
        print(f"Error: {e}") 