# toio-control-python

This repository contains the necessary files to control Toio robots using Python and Java Processing. The robots can be controlled through a server-client architecture, where the server communicates with the Toio robots via Bluetooth, and the client provides a graphical interface for controlling the robots.

## Files

### Python Modules

- `setup.py`: Configuration file for setting up the Python package.
- `toio_py/constants.py`: Contains the UUIDs (MacOS) and BLE MAC Addresses (Windows and Linux) for connecting to Toio robots on different platforms. Note that toio UUIDs change between different MacOS machines, so first run `/utils/discover_cubes.py` to obtain UUIDs for each cube.
- `toio_py/cube.py`: Core module for controlling individual Toio robots using BLE (Bluetooth Low Energy).
- `utils/cubeManager.py`: Manages multiple Toio robots and handles OSC (Open Sound Control) messages to control the robots.
- `utils/discover_cubes.py`: Utility script to discover Toio cubes and their UUIDs.
- `utils/id_reader.py`: Reads and processes cube IDs.

### Examples

- `examples/gui_client/gui_client.pde`: Java Processing code for the GUI client that allows users to interact with the Toio robots.
- `examples/gui_client/toioCube.pde`: Defines the `toioCube` class used in the Processing GUI client.
- `examples/gui_client/toioMats.pde`: Defines the `toioMats` class for managing mat configurations in the GUI client.
- `examples/gui_client/server.pde`: Server-side Processing code for handling OSC messages.
- `examples/check_functions.py`: Script to test various functions of the Toio control library.
- `examples/connection_test.py`: Script to test the connection to Toio cubes.
- `examples/multiple_cubes.py`: Example script to control multiple cubes simultaneously.

## Setup

### Python Environment

1. **Install the Python package:**
   ```sh
   python setup.py install
   ```

### Processing Environment

1. **Install Processing:** Download and install Processing from [here](https://processing.org/download/).

2. **Install the necessary libraries in Processing:**
   - Go to `Sketch -> Import Library -> Add Library`.
   - Install `oscP5` and `controlP5`.

## Usage

### Running the Server

1. **Start the server:**
   ```sh
   python utils/cubeManager.py
   ```

### Running the GUI Client

1. **Open Processing:**

   - Open `gui_client.pde`, `toioCube.pde`, and `toioMats.pde` in Processing.
   - Ensure all files are in the same directory.

2. **Run the GUI Client:**
   - Click the play button in Processing to start the GUI client.

### Interacting with the GUI Client

1. **Connect a Cube:**

   - Enter the cube ID in the textbox and click the `Connect` button.
   - A new Toio cube will appear in the middle of the mat.

2. **Disconnect a Cube:**

   - Enter the cube ID in the textbox and click the `Disconnect` button.
   - The selected Toio cube will be removed from the mat.

3. **Select and Move Cubes:**
   - Left-click and drag to select multiple cubes. Selected cubes will be highlighted in green.
   - Right-click to move the selected cubes to a new position. The cubes will maintain their relative positions.

### Updating Cube Positions

- The GUI client will automatically update the positions of the cubes as they move on the mat. The server sends continuous position updates to the client.

### Adjusting Scale and Centering the Mat

- The mat is always centered in the window, and the scale can be adjusted using the `scaleFactor` variable in `gui_client.pde`.
