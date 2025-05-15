import asyncio
from bleak import BleakClient

ADDRESS = "04:A3:16:A8:94:D2"
UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"

def notification_handler(sender, data):
    print(f"Response: {data.decode('utf-8', errors='replace')}")

async def run():
    print("Connecting to BT05...")
    async with BleakClient(ADDRESS) as client:
        print("Connected!")
        
        # Set up notifications to see responses
        await client.start_notify(UUID, notification_handler)
        
        # Send commands with proper line endings
        commands = [
            "AT+BAUD4",   # Set baud rate to 9600
            "AT+NOTI1",   # Enable notifications
            "AT+ROLE0"    # Set peripheral mode
        ]
        
        for cmd in commands:
            cmd_bytes = (cmd + "\r\n").encode()
            print(f"Sending: {cmd}")
            await client.write_gatt_char(UUID, cmd_bytes)
            await asyncio.sleep(1)
        
        print("Configuration complete!")
        print("Waiting to receive data (10 seconds)...")
        await asyncio.sleep(10)

# Run the tool
asyncio.run(run()) 