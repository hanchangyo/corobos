import asyncio
from bleak import BleakScanner

async def run():
    devices = await BleakScanner.discover()
    for device in devices:
        if device.name and "toio" in device.name:
            print(f"{device.address}: {device.name}")

asyncio.run(run())
