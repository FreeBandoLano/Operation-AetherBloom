import asyncio
from bleak import BleakClient, BleakScanner

async def run():
    print("Scanning for BT05...")
    device = await BleakScanner.find_device_by_address("04:A3:16:A8:94:D2")
    if not device:
        print("BT05 not found! Make sure it's powered on.")
        return
    
    print(f"Found device: {device.name or 'Unknown'} ({device.address})")
    print("Connecting...")
    
    async with BleakClient(device) as client:
        print("Connected!")
        
        # Get all services and characteristics
        for service in client.services:
            print(f"Service: {service.uuid}")
            for char in service.characteristics:
                props = ", ".join(char.properties)
                print(f"  Characteristic: {char.uuid}")
                print(f"    Properties: {props}")
                
                # Try to set up notification if supported
                if "notify" in char.properties:
                    try:
                        await client.start_notify(char.uuid, 
                            lambda s, d: print(f"[{char.uuid}] Response: {d.hex()}"))
                        print(f"    ✓ Notification set up")
                    except Exception as e:
                        print(f"    ✗ Could not set up notification: {str(e)}")
        
        # Try to send AT command to all writable characteristics
        print("\nTesting writable characteristics...")
        test_cmd = b"AT\r\n"
        
        for service in client.services:
            for char in service.characteristics:
                if "write" in char.properties:
                    try:
                        print(f"Writing to {char.uuid}...")
                        await client.write_gatt_char(char.uuid, test_cmd)
                        print(f"  ✓ Success!")
                        # Remember this characteristic
                        print(f"\n*** WORKING CHARACTERISTIC: {char.uuid} ***\n")
                    except Exception as e:
                        print(f"  ✗ Failed: {str(e)}")
        
        print("Discovery complete. Waiting for notifications (10 seconds)...")
        await asyncio.sleep(10)

# Run the discovery tool
asyncio.run(run()) 