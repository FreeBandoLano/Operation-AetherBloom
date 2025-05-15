import asyncio
from bleak import BleakScanner

async def scan():
    print("Scanning for BLE devices...")
    devices = await BleakScanner.discover()
    print(f"Found {len(devices)} devices:")
    for d in devices:
        print(f"{d.name or '(No name)'}: {d.address}")

if __name__ == "__main__":
    asyncio.run(scan()) 