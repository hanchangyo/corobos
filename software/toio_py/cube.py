'''
core cube
'''

import struct
import platform
import asyncio
import math

from bleak import BleakClient
from . import constants


class MovementType:
    RotateWhileMoving = 0x00  # The cube rotates while moving along its path.
    RotateWhileMovingNoReverse = 0x01  # The cube rotates while moving forward without reversing.
    RotateThenMove = 0x02  # The cube rotates in place first and then moves straight.


class SpeedType:
    ConstantSpeed = 0x00  # The speed of the cube remains constant throughout the movement.
    AccelerateToTarget = 0x01  # The cube accelerates as it moves towards the target position.
    DecelerateToTarget = 0x02  # The cube decelerates as it approaches the target position.
    AccelerateThenDecelerate = 0x03  # The cube accelerates to a midpoint, then decelerates as it reaches the target position.


class CoreCube(BleakClient):
    BATTERY_CHARACTERISTIC_UUID =       ("10B20108-5B3B-4571-9508-CF3EFCD7BBAE")
    LAMP_CHARACTERISTIC_UUID =          ("10B20103-5B3B-4571-9508-CF3EFCD7BBAE")
    MOTOR_CHARACTERISTIC_UUID =         ("10B20102-5B3B-4571-9508-CF3EFCD7BBAE")
    SOUND_CHARACTERISTIC_UUID =         ("10B20104-5B3B-4571-9508-CF3EFCD7BBAE")
    BUTTON_CHARACTERISTIC_UUID =        ("10B20107-5B3B-4571-9508-CF3EFCD7BBAE")
    ID_READER_CHARACTERISTIC_UUID =     ("10B20101-5B3B-4571-9508-CF3EFCD7BBAE")
    MOTION_MAGNET_CHARACTERISTIC_UUID = ("10B20106-5B3B-4571-9508-CF3EFCD7BBAE")
    SETTINGS_CHARACTERISTIC_UUID =      ("10B201FF-5B3B-4571-9508-CF3EFCD7BBAE")

    def __init__(self, cube_number: int, debug: bool = True):
        os_type = platform.system()
        if os_type == "Darwin":  # MacOS
            address = constants.toioUUID_mac[cube_number]
        elif os_type == "Linux" or os_type == "Windows":
            address = constants.toioBLE_address[cube_number]
        else:
            raise ValueError(f"Unsupported operating system: {os_type}")

        self.cube_id = cube_number
        self.client = BleakClient(address)
        self.battery = None
        self.x = self.y = self.angle = None
        self.x_sens = self.y_sens = self.angle_sens = None
        self.is_on_mat = False
        self.s_id = None
        self.button = False
        self.motor_response = None
        self.control_identifier = cube_number
        self.position_notification_counter = 0
        self.battery_notification_counter = 0
        self.posture = None
        self.last_motor_l = 0
        self.last_motor_r = 0

        self.debug = debug

    async def connect(self) -> bool:
        try:
            return await self.client.connect()
        except Exception as e:
            # Handle exceptions (e.g., device not found, connection error)
            print(f"Connection failed: {e}")
            return False

    async def disconnect(self) -> bool:
        try:
            await self.client.disconnect()
            return True
        except Exception as e:
            # Handle exceptions (e.g., error during disconnection)
            print(f"Disconnection failed: {e}")
            return False

    async def read_battery(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        battery_data = await self.client.read_gatt_char(self.BATTERY_CHARACTERISTIC_UUID)
        self.battery = self._parse_battery_data(battery_data)

    def _parse_battery_data(self, data):
        # The battery level is a single byte representing the percentage.
        return int(data[0])

    async def start_battery_notifications(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")
        await self.client.start_notify(self.BATTERY_CHARACTERISTIC_UUID, self.battery_notification_handler)

    def battery_notification_handler(self, sender, data):
        self.battery = data[0]  # Battery level is a single byte representing the percentage
        if self.debug:
            print(f"Battery level: {self.battery}%")
        self.battery_notification_counter += 1  # Increment counter when position is updated

    async def read_position_id(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        position_data = await self.client.read_gatt_char(self.ID_READER_CHARACTERISTIC_UUID)
        self._parse_position_data(position_data)

    def _parse_position_data(self, data):
        if data[0] == 0x03:  # Position ID missed
            self.is_on_mat = False
        else:
            self.is_on_mat = True
            self.x = struct.unpack_from('<H', data, 1)[0]
            self.y = struct.unpack_from('<H', data, 3)[0]
            self.angle = struct.unpack_from('<H', data, 5)[0]
            self.x_sens = struct.unpack_from('<H', data, 7)[0]
            self.y_sens = struct.unpack_from('<H', data, 9)[0]
            self.angle_sens = struct.unpack_from('<H', data, 11)[0]

    async def start_position_notifications(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")
        await self.client.start_notify(self.ID_READER_CHARACTERISTIC_UUID, self.position_notification_handler)

    def position_notification_handler(self, sender, data):
        if data[0] == 0x03:  # Position ID missed
            self.is_on_mat = False
            if self.debug: print("Position ID missed - Cube is not on the mat")
        elif data[0] == 0x02:  # Standard ID
            self.is_on_mat = True
            self.s_id = struct.unpack_from('<I', data, 1)[0]
            self.angle = struct.unpack_from('<H', data, 5)[0]
            if self.debug: print(f"Standard ID: {self.s_id}, Angle: {self.angle}")
        else:
            self.is_on_mat = True
            self.x = struct.unpack_from('<H', data, 1)[0]
            self.y = struct.unpack_from('<H', data, 3)[0]
            self.angle = struct.unpack_from('<H', data, 5)[0]
            self.x_sens = struct.unpack_from('<H', data, 7)[0]
            self.y_sens = struct.unpack_from('<H', data, 9)[0]
            self.angle_sens = struct.unpack_from('<H', data, 11)[0]
            # if self.debug: print(f"Position updated: x={self.x}, y={self.y}, angle={self.angle}")
        self.position_notification_counter += 1  # Increment counter when position is updated

    async def control_led(self, r: int, g: int, b: int, duration: int):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        # Duration is scaled by a factor of 10 milliseconds
        duration_byte = int(duration / 10)
        if duration_byte < 0 or duration_byte > 255:
            raise ValueError("Duration must be between 0 and 2550 milliseconds")

        # Construct the command
        command = bytes([0x03, duration_byte, 0x01, 0x01, r, g, b])

        # Send the command
        await self.client.write_gatt_char(self.LAMP_CHARACTERISTIC_UUID, command, response=True)

    async def start_button_notifications(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")
        await self.client.start_notify(self.BUTTON_CHARACTERISTIC_UUID, self.button_notification_handler)

    def button_notification_handler(self, data):
        if data[0] == 0x01:  # Function button ID
            self.button = (data[1] == 0x80)  # True if pressed, False if released
            if self.debug: print(f"Button pressed: {self.button}")

    async def play_sound_effect(self, effect_id: int, volume: int):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        if not (0 <= effect_id <= 10) or not (0 <= volume <= 255):
            raise ValueError("Invalid effect ID or volume")

        command = bytes([0x02, effect_id, volume])
        await self.client.write_gatt_char(self.SOUND_CHARACTERISTIC_UUID, command, response=True)

    async def play_midi_sequence(self, repeat: int, operations: list):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        if not (0 <= repeat <= 255) or not (1 <= len(operations) <= 59):
            raise ValueError("Invalid repeat count or number of operations")

        command = bytearray([0x03, repeat, len(operations)])
        for duration, note, volume in operations:
            if not (1 <= duration <= 255) or not (0 <= note <= 128) or not (0 <= volume <= 255):
                raise ValueError("Invalid duration, note, or volume in operations")
            command.extend([duration, note, volume])

        await self.client.write_gatt_char(self.SOUND_CHARACTERISTIC_UUID, command, response=True)

    async def stop_playback(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        command = bytearray([0x01])
        await self.client.write_gatt_char(self.SOUND_CHARACTERISTIC_UUID, command, response=True)

    async def moveRaw(self, l: int, r: int, duration: int, wait: bool = True):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        if not (-115 <= l <= 115) or not (-115 <= r <= 115) or not (0 <= duration <= 2550):
            raise ValueError("Invalid motor speed or duration")

        # Determine the direction for each motor
        left_direction = 0x02 if l < 0 else 0x01
        right_direction = 0x02 if r < 0 else 0x01

        # Convert speeds to positive values
        l_speed = abs(l)
        r_speed = abs(r)

        # Duration is scaled by a factor of 10 milliseconds
        duration_byte = int(duration / 10)

        command = bytearray([0x02, 0x01, left_direction, l_speed, 0x02, right_direction, r_speed, duration_byte])
        await self.client.write_gatt_char(self.MOTOR_CHARACTERISTIC_UUID, command, response=False)

        # Store last motor speeds for odometry calculations
        self.last_motor_l = l
        self.last_motor_r = r

        # Wait for the duration of the movement
        if wait: await asyncio.sleep(duration / 1000)  # Convert milliseconds to seconds

    async def start_motor_response_notifications(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")
        await self.client.start_notify(self.MOTOR_CHARACTERISTIC_UUID, self.motor_response_handler)

    def motor_response_handler(self, sender, data):
        if data[0] == 0x83 and data[1] == self.control_identifier:  # Check control identifier
            self.motor_response = data

    async def moveTo(self, x: int, y: int, angle: int,
                     speed: int, move_type: int = MovementType.RotateWhileMoving, speed_type: int = SpeedType.ConstantSpeed,
                     timeout: int = 5, rotate: bool = True) -> bool:
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        if not (0 <= timeout <= 255) or not (10 <= speed <= 255):
            raise ValueError("Invalid control identifier, timeout, or speed")

        self.motor_response = None  # Reset motor response

        if rotate:
            angle = angle & 0x1FFF  # Ensure the lower 13 bits are set
        else:
            angle = (angle & 0x1FFF) | (0x05 << 13)  # Set the upper 3 bits to 0x05

        command = bytearray([0x03, self.control_identifier, timeout, move_type, speed, speed_type, 0x00])
        command += struct.pack('<H', x)
        command += struct.pack('<H', y)
        command += struct.pack('<H', angle)

        await self.client.write_gatt_char(self.MOTOR_CHARACTERISTIC_UUID, command, response=False)

        # Wait for the response
        start_time = asyncio.get_event_loop().time()
        while self.motor_response is None and (asyncio.get_event_loop().time() - start_time) < (timeout + 2):
            await asyncio.sleep(0.03)

        # Check the response
        if self.motor_response and self.motor_response[1] == self.control_identifier and self.motor_response[2] == 0x00:
            return True
        return False

    async def rotateToAngle(self, angle: int, speed: int, timeout: int = 5) -> bool:
        if self.x is None or self.y is None:
            print("Current position is unknown. Ensure position notifications are active.")
            return False

        # Use the moveTo function with the current x, y and new angle
        return await self.moveTo(self.x, self.y, angle, speed, move_type=MovementType.RotateThenMove, timeout=timeout)

    async def start_posture_notifications(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")
        await self.client.start_notify(self.MOTION_MAGNET_CHARACTERISTIC_UUID, self.posture_notification_handler)

    def posture_notification_handler(self, sender, data):
        if len(data) < 6:
            if self.debug:
                print("Invalid data length for posture notification.")
            return

        motion_type = data[0]
        flat_status = data[1]  # 0x01: Flat, 0x00: Not flat
        collision = data[2]  # 0x01: Collision detected, 0x00: No collision
        double_tap = data[3]  # 0x01: Double tap detected, 0x00: No double tap
        posture = data[4]  # Posture value (1-6)
        shake_level = data[5]  # Shake level (0x00: No shake, 0x01-0x0A: Shake levels)

        posture_mapping = {
            1: "Top",
            2: "Bottom",
            3: "Back",
            4: "Front",
            5: "Right",
            6: "Left"
        }

        self.posture = posture
        posture_description = posture_mapping.get(posture, "Unknown")

        if self.debug:
            print(f"Motion Type: {motion_type}")
            print(f"Flat Status: {'Flat' if flat_status == 0x01 else 'Not Flat'}")
            print(f"Collision: {'Detected' if collision == 0x01 else 'None'}")
            print(f"Double Tap: {'Detected' if double_tap == 0x01 else 'None'}")
            print(f"Posture: {posture} ({posture_description})")
            print(f"Shake Level: {shake_level}")

    async def request_motion_info(self):
        if not self.client.is_connected:
            raise RuntimeError("Cube is not connected")

        # Construct the command to request motion detection information
        command = bytearray([0x81])

        # Write the command to the motion/magnet characteristic
        await self.client.write_gatt_char(self.MOTION_MAGNET_CHARACTERISTIC_UUID, command, response=True)

    async def move_to_p(self, x_target, y_target, angle_target=None, maximum_speed=70, k_p=0.5, k_ang=0.1, update_interval=0.05, timeout=10, reach_threshold=8, reach_angle_threshold=5):
        # Initialize odometry if position is unavailable
        if self.x is None or self.y is None:
            self.x, self.y, self.angle = 0, 0, 0  # Default starting position

        x_current, y_current, angle_current = self.x, self.y, self.angle

        # Start time for timeout
        start_time = asyncio.get_event_loop().time()

        # PID control loop
        while True:
            # Check for timeout
            if asyncio.get_event_loop().time() - start_time > timeout:
                if self.debug:
                    print("Timeout reached while trying to move to the target position.")
                return False

            # Use cube's position if available, otherwise fallback to odometry
            if self.is_on_mat:
                x_current, y_current, angle_current = self.x, self.y, self.angle
            else:
                # Update odometry based on motor commands
                dt = update_interval  # Time step
                # convert last motor speeds to mat coordinates
                v = 1.0219 * (self.last_motor_l + self.last_motor_r) - 0.1901  # Linear velocity in dot/s
                omega = 6.065 * (self.last_motor_l - self.last_motor_r)  # Angular velocity in CW deg/s

                angle_current = (angle_current + omega * dt) % 360
                x_current += v * dt * math.cos(math.radians(angle_current))
                y_current += v * dt * math.sin(math.radians(angle_current))
                self.x, self.y, self.angle = x_current, y_current, angle_current

            # Calculate errors
            x_error = x_target - x_current
            y_error = y_target - y_current

            # Calculate distance and angle to the target
            distance_error = math.sqrt(x_error**2 + y_error**2)
            target_angle = math.degrees(math.atan2(y_error, x_error))
            angle_error = (target_angle - angle_current + 180) % 360 - 180

            drive_dir = 1 # 1 for forward, -1 for backward
            if abs(angle_error) > 90:
                drive_dir = -1
                if angle_error > 0:
                    angle_error -= 180
                else:
                    angle_error += 180
            # this adjusts the angle error to be within -90 to 90 degrees

            linear_speed = drive_dir * int(max(min(k_p * distance_error, maximum_speed), 8))
            angular_speed = int(max(min(k_p * angle_error, maximum_speed), -maximum_speed))

            motor_l = linear_speed + angular_speed
            motor_r = linear_speed - angular_speed

            motor_l = max(min(motor_l, maximum_speed), 8 if motor_l > 0 else -maximum_speed)
            motor_r = max(min(motor_r, maximum_speed), 8 if motor_r > 0 else -maximum_speed)

            # Reach condition
            if distance_error < reach_threshold:
                if angle_target is not None:
                    # Rotate to the target angle after reaching the position
                    angle_error = (angle_target - angle_current + 180) % 360 - 180
                    while abs(angle_error) > reach_angle_threshold:  # Allowable angle error threshold
                        angular_speed = int(max(min(k_ang * angle_error, maximum_speed), -maximum_speed))
                        if abs(angular_speed) < 8:
                            angular_speed = 8 if angular_speed > 0 else -8
                        motor_l = angular_speed
                        motor_r = -angular_speed

                        if self.debug:
                            print(f"Adjusting angle: Current angle={angle_current}, Target angle={angle_target}, Angle error={angle_error}")
                            print(f"Motor speeds for rotation: Left={motor_l}, Right={motor_r}")

                        await self.moveRaw(motor_l, motor_r, update_interval * 2 * 1000, wait=False)
                        await asyncio.sleep(update_interval)

                        if self.is_on_mat:
                            angle_current = self.angle
                        else:
                            angle_current = (angle_current + angular_speed * update_interval) % 360
                        angle_error = (angle_target - angle_current + 180) % 360 - 180

                return True

            if self.debug:
                print(f"is_on_mat: {self.is_on_mat}")
                print(f"Current position: x={x_current}, y={y_current}, angle={angle_current}")
                print(f"Target position: x={x_target}, y={y_target}, angle={angle_target}")
                print(f"Errors: distance_error={distance_error}, angle_error={angle_error}")
                print(f"Motor speeds: Left={motor_l}, Right={motor_r}")

            await self.moveRaw(motor_l, motor_r, update_interval * 2 * 1000, wait=False)
            await asyncio.sleep(update_interval)
