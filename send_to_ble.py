import asyncio
import sys
from bleak import BleakClient

# Default MAC address
ADDRESS = "04:A3:16:A8:94:D2"
if len(sys.argv) > 1:
    ADDRESS = sys.argv[1]

# The common UART service UUID for BLE modules like BT05
UART_SERVICE_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb"
UART_TX_CHAR_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"  # Same UUID for both RX and TX on many BLE modules

# Test message to send
TEST_MESSAGE = b"HELLO"
if len(sys.argv) > 2:
    TEST_MESSAGE = sys.argv[2].encode('utf-8')

async def main():
    print(f"Connecting to {ADDRESS}...")
    async with BleakClient(ADDRESS) as client:
        print(f"Connected: {client.is_connected}")
        
        # Get all services
        services = await client.get_services()
        
        # Find write characteristics
        write_chars = []
        for service in services:
            for char in service.characteristics:
                if "write" in char.properties:
                    write_chars.append(char.uuid)
                    print(f"Found writable characteristic: {char.uuid}")
        
        # Try to write to the standard UART characteristic first
        try:
            print(f"\nAttempting to write to {UART_TX_CHAR_UUID}...")
            await client.write_gatt_char(UART_TX_CHAR_UUID, TEST_MESSAGE)
            print(f"Successfully wrote to {UART_TX_CHAR_UUID}")
        except Exception as e:
            print(f"Error writing to {UART_TX_CHAR_UUID}: {e}")
            
            # Try other writable characteristics
            if write_chars:
                for char_uuid in write_chars:
                    try:
                        print(f"Attempting to write to {char_uuid}...")
                        await client.write_gatt_char(char_uuid, TEST_MESSAGE)
                        print(f"Successfully wrote to {char_uuid}")
                    except Exception as e2:
                        print(f"Error writing to {char_uuid}: {e2}")
            else:
                print("No writable characteristics found")
        
        print("Waiting 5 seconds to see if there's any response...")
        await asyncio.sleep(5)

        # Add after the connection is established
        AT_CONFIG = b"AT+BAUD4"  # Example: Set baud rate to 9600
        AT_ENABLE = b"AT+NOTI1"  # Enable notifications
        await client.write_gatt_char(UART_TX_CHAR_UUID, AT_CONFIG)
        await client.write_gatt_char(UART_TX_CHAR_UUID, AT_ENABLE)

if __name__ == "__main__":
    asyncio.run(main()) 