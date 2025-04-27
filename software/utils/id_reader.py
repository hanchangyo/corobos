import asyncio
import argparse
from toio_py import cube

async def main(cube_id):
    Cube = cube.CoreCube(cube_id, debug=True)
    await Cube.connect()
    await Cube.control_led(r=255, g=0, b=0, duration=0)
    await Cube.start_position_notifications()
    await Cube.start_battery_notifications()

    try:
        while True:
            await asyncio.sleep(0.01)
    except KeyboardInterrupt:
        pass

    await Cube.disconnect()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='ID Reader for toio cube.')
    parser.add_argument('cube_id', type=int, help='The ID of the cube to connect to.')

    args = parser.parse_args()

    asyncio.run(main(args.cube_id))
