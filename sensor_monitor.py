import asyncio
import time
from bleak import BleakClient

# BT05 device details
ADDRESS = "98:7B:F3:6E:92:43"
NOTIFY_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"

def handle_data(sender, data):
    timestamp = time.strftime("%H:%M:%S")
    print(f"[{timestamp}] Received data: {data.hex(' ')}")
    try:
        print(f"ASCII: {data.decode('utf-8')}")
    except:
        pass
    
    # Log to file for later analysis
    with open("sensor_data.log", "a") as f:
        f.write(f"{timestamp},{data.hex(' ')}\n")

async def run():
    print(f"Connecting to BT05 at {ADDRESS}...")
    async with BleakClient(ADDRESS) as client:
        print("Connected!")
        
        print("\nDiscovering services and characteristics...")
        for service in client.services:
            print(f"[Service] {service.uuid}")
            for char in service.characteristics:
                print(f"  [Characteristic] {char.uuid} | Properties: {', '.join(char.properties)}")
                for descriptor in char.descriptors:
                    print(f"    [Descriptor] {descriptor.uuid} ({descriptor.handle})")
        print("Service discovery complete.\n")

        print(f"Attempting to start notifications on {NOTIFY_UUID}...")
        # Set up notification handler
        await client.start_notify(NOTIFY_UUID, handle_data)
        
        print("Monitoring started. Press Ctrl+C to stop.")
        print("Waiting for sensor data...")
        
        try:
            # Keep running until interrupted
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            pass
        finally:
            await client.stop_notify(NOTIFY_UUID)
            print("Monitoring stopped.")

if __name__ == "__main__":
    asyncio.run(run()) 