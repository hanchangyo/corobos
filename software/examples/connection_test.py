import asyncio
import argparse
from toio_py import cube


async def connect_cube(cube):
    while not await cube.connect():
        print(f"Retrying connection for cube {cube.cube_id}")
        await asyncio.sleep(1)  # wait a bit before retrying


async def manage_connections(cubes):
    await asyncio.gather(*(connect_cube(cube) for cube in cubes))
    print("All cubes are now connected.")


async def main():
    Cubes = [cube.CoreCube(cube_id) for cube_id in range(1, 8 + 1)]

    # Connect all cubes
    await manage_connections(Cubes)

    # Connect cubes and start notifications
    # await asyncio.gather(*(c.connect() for c in Cubes))
    await asyncio.gather(*(c.control_led(0, 255, 0, 0) for c in Cubes))
    await asyncio.gather(*(c.moveRaw(30, -30, 500) for c in Cubes))
    await asyncio.gather(*(c.disconnect() for c in Cubes))

if __name__ == "__main__":
    asyncio.run(main())
