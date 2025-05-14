import asyncio
import sys
from bleak import BleakClient

# Default MAC address
ADDRESS = "04:A3:16:A8:94:D2"
if len(sys.argv) > 1:
    ADDRESS = sys.argv[1]

# The common UART service UUID for BLE modules like BT05
UART_SERVICE_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb"
UART_RX_CHAR_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"

def handle_data(sender, data):
    print(f"Received data: {data.hex(' ')}")
    try:
        print(f"ASCII: {data.decode('utf-8')}")
    except:
        pass  # Not valid UTF-8

async def main():
    print(f"Connecting to {ADDRESS}...")
    async with BleakClient(ADDRESS) as client:
        print(f"Connected: {client.is_connected}")
        
        # Get all services
        services = await client.get_services()
        print("Services:")
        for service in services:
            print(f"Service: {service.uuid}")
            for char in service.characteristics:
                print(f"  Characteristic: {char.uuid}")
                print(f"    Properties: {', '.join(char.properties)}")
        
        # Try to subscribe to the UART characteristic
        try:
            print(f"\nSubscribing to notifications on {UART_RX_CHAR_UUID}...")
            await client.start_notify(UART_RX_CHAR_UUID, handle_data)
        except Exception as e:
            print(f"Error subscribing to notifications: {e}")
            # Try to find a characteristic with notify property
            print("Searching for characteristics with notify property...")
            for service in services:
                for char in service.characteristics:
                    if "notify" in char.properties:
                        print(f"Found notify characteristic: {char.uuid}")
                        try:
                            print(f"Subscribing to {char.uuid}...")
                            await client.start_notify(char.uuid, handle_data)
                            print(f"Successfully subscribed to {char.uuid}")
                        except Exception as e2:
                            print(f"Error subscribing to {char.uuid}: {e2}")
        
        print("Waiting for data (press Ctrl+C to exit)...")
        try:
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            pass
        finally:
            try:
                await client.stop_notify(UART_RX_CHAR_UUID)
            except:
                pass
            print("Notifications stopped")

if __name__ == "__main__":
    asyncio.run(main()) 