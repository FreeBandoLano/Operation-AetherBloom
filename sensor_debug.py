import asyncio
import time
from bleak import BleakClient, BleakScanner

# BT05 device details
ADDRESS = "04:A3:16:A8:94:D2"
NOTIFY_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"

# Test commands to potentially trigger data flow
TEST_COMMANDS = [
    b"AT\r\n",
    b"AT+VERSION\r\n",
    b"\x01",  # Some modules require single bytes
    b"\x0A",  # Line Feed
    b"\x0D",  # Carriage Return
]

def handle_data(sender, data):
    timestamp = time.strftime("%H:%M:%S")
    hex_data = ' '.join(f'{b:02x}' for b in data)
    print(f"[{timestamp}] Received: {hex_data}")
    try:
        ascii_data = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in data)
        print(f"ASCII: {ascii_data}")
    except:
        pass

async def run():
    # First scan to make sure device is available
    print("Scanning for BT05...")
    scanner = BleakScanner()
    devices = await scanner.discover()
    bt05_found = False
    
    for device in devices:
        if device.address == ADDRESS:
            bt05_found = True
            print(f"Found BT05: {device.name or 'Unknown'} ({device.address})")
    
    if not bt05_found:
        print(f"WARNING: BT05 device with address {ADDRESS} not found in scan")
        print("Will try to connect anyway...")
    
    print(f"\nConnecting to BT05 at {ADDRESS}...")
    try:
        async with BleakClient(ADDRESS) as client:
            print("Connected! Checking services...")
            
            # Check for all notify characteristics
            notify_chars = []
            for service in client.services:
                for char in service.characteristics:
                    props = char.properties
                    if "notify" in props:
                        notify_chars.append(char.uuid)
                        print(f"Found notify characteristic: {char.uuid}")
            
            if not notify_chars:
                print("No notify characteristics found!")
                return
                
            # Set up notification on primary characteristic
            print(f"\nSetting up notification on {NOTIFY_UUID}...")
            await client.start_notify(NOTIFY_UUID, handle_data)
            print("Notification setup complete")
            
            # Send test commands to potentially trigger responses
            print("\nSending test commands to trigger data...")
            for cmd in TEST_COMMANDS:
                cmd_hex = ' '.join(f'{b:02x}' for b in cmd)
                print(f"Sending: {cmd_hex}")
                try:
                    await client.write_gatt_char(NOTIFY_UUID, cmd)
                except Exception as e:
                    print(f"  Failed: {e}")
                await asyncio.sleep(2)
            
            # Check for other writable characteristics
            print("\nChecking for other writable characteristics...")
            for service in client.services:
                for char in service.characteristics:
                    if "write" in char.properties and char.uuid != NOTIFY_UUID:
                        print(f"Found alternative writable characteristic: {char.uuid}")
                        try:
                            await client.write_gatt_char(char.uuid, b"\x01")
                            print(f"  Successfully wrote to {char.uuid}")
                        except Exception as e:
                            print(f"  Failed to write: {e}")
            
            print("\nHARDWARE CHECK:")
            print("1. Verify sensors are properly powered")
            print("2. Check all wiring connections to BT05")
            print("3. Ensure BT05 module LED is blinking (if present)")
            print("4. Try resetting sensors or manually triggering them")
            
            print("\nMonitoring for data (60 seconds)...")
            timeout = time.time() + 60
            try:
                while time.time() < timeout:
                    await asyncio.sleep(1)
                    remaining = int(timeout - time.time())
                    if remaining % 10 == 0 and remaining > 0:
                        print(f"{remaining} seconds remaining...")
            except KeyboardInterrupt:
                pass
            finally:
                await client.stop_notify(NOTIFY_UUID)
                print("Monitoring stopped.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(run()) 