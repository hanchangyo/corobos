import asyncio
import sys
import math
from pythonosc import dispatcher, osc_server, udp_client
from toio_py.cube import CoreCube

class CubeManager:
    def __init__(self, osc_receive_ip, osc_receive_port, osc_send_ip, osc_send_port):
        self.cubes = []
        self.dispatcher = dispatcher.Dispatcher()
        self.osc_client = udp_client.SimpleUDPClient(osc_send_ip, osc_send_port)

        # Register OSC message handlers
        self.dispatcher.map("/cube/*/connect", self.handle_connect)
        self.dispatcher.map("/cube/*/disconnect", self.handle_disconnect)
        self.dispatcher.map("/cube/*/led", self.handle_control_led)
        self.dispatcher.map("/cube/*/move", self.handle_move_to)
        self.dispatcher.map("/cube/*/sound", self.handle_play_sound_effect)
        self.dispatcher.map("/cube/*/pos", self.handle_get_position)
        self.dispatcher.map("/cube/*/motor", self.handle_motor_control)
        self.dispatcher.map("/cube/*/p_move", self.handle_move_to_p)

        # Create and set a new event loop
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        self.server = osc_server.AsyncIOOSCUDPServer(
            (osc_receive_ip, osc_receive_port), self.dispatcher, self.loop
        )

    def start_server(self):
        self.server.serve()

    def handle_connect(self, address, *args):
        print(f"Received connect command: {address} {args}")
        asyncio.ensure_future(self._handle_connect(address, *args))

    async def _handle_connect(self, address, *args):
        cube_index = int(address.split('/')[2])
        if len(self.cubes) <= cube_index:
            self.cubes.extend([None] * (cube_index - len(self.cubes) + 1))
        if not self.cubes[cube_index]:
            self.cubes[cube_index] = CoreCube(cube_index)
        cube = self.cubes[cube_index]
        if cube:
            connected = await cube.connect()
            print(f"Cube {cube_index} connected: {connected}")
            if connected:
                self.osc_client.send_message(f"/cube/{cube_index}/connect", [1])
            await cube.start_motor_response_notifications()
            await cube.start_position_notifications()
            await cube.start_battery_notifications()
            await cube.start_posture_notifications()
            asyncio.ensure_future(self.send_position_updates(cube_index, cube))
            asyncio.ensure_future(self.send_battery_updates(cube_index, cube))
            asyncio.ensure_future(self.send_posture_updates(cube_index, cube))
            await cube.request_motion_info()

    async def send_position_updates(self, cube_index, cube):
        last_counter = cube.position_notification_counter
        while True:
            if last_counter != cube.position_notification_counter:
                last_counter = cube.position_notification_counter
                if cube.x is not None and cube.y is not None:
                    self.osc_client.send_message(f"/cube/{cube_index}/pos", [cube.x, cube.y, cube.angle])
                if not cube.is_on_mat:
                    self.osc_client.send_message(f"/cube/{cube_index}/pos", [-1, -1, -1])
            await asyncio.sleep(0.01)  # Update interval

    async def send_posture_updates(self, cube_index, cube):
        last_posture = None
        while True:
            if last_posture != cube.posture:
                last_posture = cube.posture
                self.osc_client.send_message(f"/cube/{cube_index}/posture", [cube.posture])
            await asyncio.sleep(0.1)  # Update interval

    def handle_disconnect(self, address, *args):
        print(f"Received disconnect command: {address} {args}")
        asyncio.ensure_future(self._handle_disconnect(address, *args))

    async def _handle_disconnect(self, address, *args):
        cube_index = int(address.split('/')[2])
        cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None
        if cube:
            disconnected = await cube.disconnect()
            if disconnected:
                self.osc_client.send_message(f"/cube/{cube_index}/disconnect", [1])
                self.cubes[cube_index] = None
            print(f"Cube {cube_index} disconnected: {disconnected}")

    def handle_control_led(self, address, *args):
        print(f"Received control led command: {address} {args}")
        asyncio.ensure_future(self._handle_control_led(address, *args))

    async def _handle_control_led(self, address, *args):
        cube_index = int(address.split('/')[2])
        r, g, b, duration = args
        cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None
        if cube:
            await cube.control_led(r, g, b, duration)
            print(f"Cube {cube_index} LED set to ({r}, {g}, {b}) for {duration}ms")

    async def send_battery_updates(self, cube_index, cube):
        last_counter = cube.battery_notification_counter
        while True:
            if last_counter != cube.battery_notification_counter:
                last_counter = cube.battery_notification_counter
                self.osc_client.send_message(f"/cube/{cube_index}/battery", [cube.battery])
            await asyncio.sleep(5.0)  # Update interval

    def handle_move_to(self, address, *args):
        print(f"Received move command: {address} {args}")
        asyncio.ensure_future(self._handle_move_to(address, *args))

    async def _handle_move_to(self, address, *args):
        try:
            cube_index = int(address.split('/')[2])
            cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None

            if len(args) == 3:
                x, y, speed = args
                angle = 0  # Default angle if not provided
                rotate = False
            elif len(args) == 4:
                x, y, angle, speed = args
                rotate = True
            else:
                print('Invalid arguments: Expected 3 or 4.')
                return

            if cube:
                # Execute the move command
                success = await cube.moveTo(x, y, angle, speed, rotate=rotate)

                if not success and not cube.is_on_mat:
                    print(f"Cube {cube_index} lost position, switching to move_to_p.")
                    success = await cube.move_to_p(x, y, angle)

                # Send feedback to the client
                goal_status = 1 if success else 0
                self.osc_client.send_message(f"/cube/{cube_index}/move_goal", [goal_status])

                # Log the result
                print(f"Cube {cube_index} moved to (x={x}, y={y}, angle={angle}) at speed={speed}: {success}")
        except (IndexError, ValueError) as e:
            print(f"Error handling move command: {e}")

    def handle_play_sound_effect(self, address, *args):
        print(f"Received play sound effect command: {address} {args}")
        asyncio.ensure_future(self._handle_play_sound_effect(address, *args))

    async def _handle_play_sound_effect(self, address, *args):
        cube_index = int(address.split('/')[2])
        effect_id, volume = args
        cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None
        if cube:
            await cube.play_sound_effect(effect_id, volume)
            print(f"Cube {cube_index} played sound effect {effect_id} at volume {volume}")

    def handle_get_position(self, address, *args):
        print(f"Received get position command: {address} {args}")
        asyncio.ensure_future(self._handle_get_position(address, *args))

    async def _handle_get_position(self, address, *args):
        cube_index = int(address.split('/')[2])
        cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None
        if cube:
            await cube.read_position_id()
            x, y, angle = cube.x, cube.y, cube.angle
            print(f"Cube {cube_index} position: x={x}, y={y}, angle={angle}")
            self.osc_client.send_message(f"/cube/{cube_index}/pos_response", [x, y, angle])

    def handle_motor_control(self, address, *args):
        print(f"Received motor control command: {address} {args}")
        asyncio.ensure_future(self._handle_motor_control(address, *args))

    async def _handle_motor_control(self, address, *args):
        cube_index = int(address.split('/')[2])
        motor_l, motor_r, duration = args
        cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None
        if cube:
            await cube.moveRaw(motor_l, motor_r, duration)
            print(f"Cube {cube_index} motors set to L: {motor_l}, R: {motor_r} for {duration}ms")

    def handle_move_to_p(self, address, *args):
        print(f"Received P move command: {address} {args}")
        asyncio.ensure_future(self._handle_move_to_p(address, *args))

    async def _handle_move_to_p(self, address, *args):
        try:
            cube_index = int(address.split('/')[2])
            cube = self.cubes[cube_index] if cube_index < len(self.cubes) else None

            if len(args) == 2:
                x_target, y_target = args
                angle_target = None
            elif len(args) == 3:
                x_target, y_target, angle_target = args
            else:
                print('Invalid arguments: Expected 2 (x_target, y_target) or 3 (x_target, y_target, angle_target).')
                return

            print(f"Cube {cube_index} P move command: {args}")

            if cube:
                # Call the new `move_to_p` method in the `CoreCube` class
                success = await cube.move_to_p(x_target, y_target, angle_target)

                # Send feedback to the client
                goal_status = 1 if success else 0
                self.osc_client.send_message(f"/cube/{cube_index}/move_goal", [goal_status])

        except (IndexError, ValueError) as e:
            print(f"Error handling P move command: {e}")

# Example usage
if __name__ == "__main__":
    osc_receive_ip = "127.0.0.1"
    osc_send_ip = "127.0.0.1"

    # Handle command-line arguments
    if len(sys.argv) == 3:
        osc_receive_ip = sys.argv[1]
        osc_send_ip = sys.argv[2]
    elif len(sys.argv) != 1:
        print("Usage:")
        print("  python cubeManager.py [osc_receive_ip] [osc_send_ip]")
        print("  If no arguments are provided, default is 127.0.0.1 for both.")
        sys.exit(1)

    osc_receive_port = 8000
    osc_send_port = 8001

    manager = CubeManager(osc_receive_ip, osc_receive_port, osc_send_ip, osc_send_port)
    manager.start_server()

    print(f'Cube manager OSC server running at: {osc_receive_ip}:{osc_receive_port}')
    print(f'Sending feedback to client at: {osc_send_ip}:{osc_send_port}')

    async def main():
        while True:
            await asyncio.sleep(1)  # Keep the server running

    manager.loop.run_until_complete(main())
