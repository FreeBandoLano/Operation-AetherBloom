import asyncio
from bleak import BleakClient

ADDRESS = "04:A3:16:A8:94:D2"
UART_TX_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"

async def configure():
    async with BleakClient(ADDRESS) as client:
        for cmd in [b"AT+BAUD4\r\n", b"AT+NOTI1\r\n"]:
            await client.write_gatt_char(UART_TX_UUID, cmd)
            await asyncio.sleep(2)

asyncio.run(configure()) 