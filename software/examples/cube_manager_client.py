import asyncio
import sys
from pythonosc import udp_client, dispatcher, osc_server

class Client:
    def __init__(self, osc_ip, osc_port):
        self.client = udp_client.SimpleUDPClient(osc_ip, osc_port)
        self.dispatcher = dispatcher.Dispatcher()
        # self.dispatcher.map("/cube/*/pos_response", self.handle_pos_response)
        self.dispatcher.map("/cube/*/pos", self.handle_pos_response)

        self.server = osc_server.ThreadingOSCUDPServer((osc_ip, osc_port + 1), self.dispatcher)
        self.server_thread = None

    def start_server(self):
        self.server_thread = asyncio.get_event_loop().run_in_executor(None, self.server.serve_forever)

    def stop_server(self):
        if self.server_thread:
            self.server.shutdown()

    def handle_pos_response(self, address, *args):
        cube_index = int(address.split('/')[2])
        x, y, angle = args
        # print(f"Cube {cube_index} position: x={x}, y={y}, angle={angle}")

    def send_message(self, address, *args):
        self.client.send_message(address, args)

async def main():
    osc_ip = "127.0.0.1"
    osc_port = 8000
    client = Client(osc_ip, osc_port)
    client.start_server()

    try:
        while True:
            command_input = input("Enter command: ").strip().lower().split()
            if len(command_input) < 1:
                print("Invalid input. Please enter a command.")
                continue

            command = command_input[0]

            if command == 'exit':
                print("Exiting client...")
                client.stop_server()
                break

            if len(command_input) < 2:
                print("Invalid input. Please enter a command followed by the cube number.")
                continue

            cube_number = command_input[1]
            try:
                cube_number = int(cube_number)
            except ValueError:
                print("Invalid cube number. Please enter a valid integer.")
                continue

            if command in ['connect', 'disconnect', 'pos']:
                client.send_message(f"/cube/{cube_number}/{command}", [])
                print(f"Sent {command} command to cube {cube_number}")

            elif command == 'led':
                try:
                    args = input("Enter r g b duration: ").strip().split()
                    r, g, b, duration = map(int, args)
                    client.send_message(f"/cube/{cube_number}/led", [r, g, b, duration])
                    print(f"Sent LED command to cube {cube_number} with values ({r}, {g}, {b}) for {duration}ms")
                except ValueError:
                    print("Invalid input. Please enter valid integers for RGB values and duration.")

            elif command == 'sound':
                try:
                    args = input("Enter effect_id volume: ").strip().split()
                    effect_id, volume = map(int, args)
                    client.send_message(f"/cube/{cube_number}/sound", [effect_id, volume])
                    print(f"Sent sound command to cube {cube_number} with effect id {effect_id} and volume {volume}")
                except ValueError:
                    print("Invalid input. Please enter valid integers for effect id and volume.")

            elif command == 'move':
                try:
                    args = input("Enter x y angle speed: ").strip().split()
                    x, y, angle, speed = map(int, args)
                    client.send_message(f"/cube/{cube_number}/move", [x, y, angle, speed])
                    print(f"Sent moveTo command to cube {cube_number} with target ({x}, {y}, {angle}) at speed {speed}")
                except ValueError:
                    print("Invalid input. Please enter valid integers for x, y, angle, and speed.")

            elif command == 'motor':
                try:
                    args = input("Enter motor_l motor_r duration: ").strip().split()
                    motor_l, motor_r, duration = map(int, args)
                    client.send_message(f"/cube/{cube_number}/motor", [motor_l, motor_r, duration])
                    print(f"Sent motor control command to cube {cube_number} with L: {motor_l}, R: {motor_r} for {duration}ms")
                except ValueError:
                    print("Invalid input. Please enter valid integers for motor speeds and duration.")

            else:
                print("Unknown command. Please try again.")
    except KeyboardInterrupt:
        print("Client terminated.")
    finally:
        client.stop_server()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Client terminated.")
        sys.exit(0)
