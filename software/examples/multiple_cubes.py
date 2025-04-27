import asyncio
import argparse
from toio_py import cube

async def main(cube_ids):
    Cubes = [cube.CoreCube(cube_id) for cube_id in cube_ids]

    # Connect cubes and start notifications
    for c in Cubes:
        await c.connect()
        await c.start_position_notifications()
        await c.start_motor_response_notifications()

    # Define the points
    points = [(120, 270), (180, 270), (180, 330), (120, 330)]

    # Number of laps around the points
    laps = 2

    for _ in range(laps):
        move_tasks = [Cubes[0].moveTo(*points[1], 90, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[1].moveTo(*points[2], 180, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[2].moveTo(*points[3], 270, 20, move_type=2, speed_type=0, timeout=5),
            ]
        await asyncio.gather(*move_tasks)
        move_tasks = [Cubes[0].moveTo(*points[2], 180, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[1].moveTo(*points[3], 270, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[2].moveTo(*points[0], 0, 20, move_type=2, speed_type=0, timeout=5),
            ]
        await asyncio.gather(*move_tasks)
        move_tasks = [Cubes[0].moveTo(*points[3], 270, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[1].moveTo(*points[0], 0, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[2].moveTo(*points[1], 90, 20, move_type=2, speed_type=0, timeout=5),
            ]
        await asyncio.gather(*move_tasks)
        move_tasks = [Cubes[0].moveTo(*points[0], 0, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[1].moveTo(*points[1], 90, 20, move_type=2, speed_type=0, timeout=5),
                      Cubes[2].moveTo(*points[2], 180, 20, move_type=2, speed_type=0, timeout=5),
            ]
        await asyncio.gather(*move_tasks)

    # Disconnect all cubes
    for c in Cubes:
        await c.disconnect()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Control multiple Toio cubes.")
    parser.add_argument('cube_ids', type=int, nargs=3, help="The IDs of the cubes to control")

    args = parser.parse_args()
    asyncio.run(main(args.cube_ids))
