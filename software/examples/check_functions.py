import asyncio
import argparse
from toio_py import cube

async def main(cube_id):
    Cube = cube.CoreCube(cube_id, debug=True)
    await Cube.connect()
    await Cube.control_led(r=255, g=255, b=0, duration=0)
    await Cube.start_position_notifications()
    await Cube.start_button_notifications()
    await Cube.start_motor_response_notifications()
    await Cube.read_battery()
    print(f'Battery: {Cube.battery} %')


    await asyncio.sleep(1)
    # Play a sound effect
    await Cube.play_sound_effect(4, 255)  # Example: Play "Mat in" sound at maximum volume

    await asyncio.sleep(1.0)

    # Play a MIDI sequence
    midi_operations = [(30, 60, 255), (30, 62, 255), (30, 64, 255)]  # Example sequence C4-D4-E4
    await Cube.play_midi_sequence(2, midi_operations)  # Play indefinitely

    await Cube.moveRaw(50, -50, 1000)

    # Rotate test
    await asyncio.sleep(1.0)
    await Cube.rotateToAngle(0, 100)
    await asyncio.sleep(1.0)
    await Cube.rotateToAngle(45, 20)
    await asyncio.sleep(1.0)
    await Cube.rotateToAngle(180, 50)
    await asyncio.sleep(1.0)

    # Move to a specific position
    success1 = await Cube.moveTo(120, 280, 0, 80, move_type=cube.MovementType.RotateThenMove, speed_type=cube.SpeedType.AccelerateThenDecelerate, timeout=5)
    print(f"Move operation success: {success1}")

    # Move to a second position
    success2 = await Cube.moveTo(170, 330, 90, 50, move_type=cube.MovementType.RotateThenMove, speed_type=cube.SpeedType.DecelerateToTarget, timeout=5)
    print(f"Move operation success: {success2}")
    await asyncio.sleep(1.0)

    # Keep the program running to receive notifications
    try:
        while not success2:
            await asyncio.sleep(0.01)
    except KeyboardInterrupt:
        pass

    await Cube.disconnect()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Get services of a specified toio cube.")
    parser.add_argument("cube_id", type=int, help="The ID of the cube to connect to.")

    args = parser.parse_args()
    asyncio.run(main(args.cube_id))
