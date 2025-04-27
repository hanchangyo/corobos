import asyncio
import argparse
from toio_py import cube

async def main(cube_id):
    cube_test = cube.CoreCube(cube_id)
    await cube_test.connect()
    characteristics = cube_test.client.services.characteristics
    for c in characteristics:
        print(f"Characteristic: {c}")
        print(f"UUID: {characteristics[c].uuid}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Get services of a specified toio cube.")
    parser.add_argument("cube_id", type=int, help="The ID of the cube to connect to.")

    args = parser.parse_args()
    asyncio.run(main(args.cube_id))
