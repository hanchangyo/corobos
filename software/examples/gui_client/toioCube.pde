class toioCube {
  int id;
  int battery;
  PVector matPosition;
  PVector displayPosition;
  PVector targetPosition;
  float angle;
  boolean selected;
  boolean is_on_mat;
  boolean targetReached;
  int posture; // New field to store posture information
  String surface;
  String previousSurface; // New field to track the previous surface
  boolean isBusy;

  toioCube(int id, float x, float y) {
    this.id = id;
    this.battery = 0;
    this.matPosition = new PVector(x, y);
    this.posture = 1;  // Initialize with floor posture by default
    this.surface = "F";
    this.previousSurface = ""; // Initialize with an empty string
    this.displayPosition = convert2DisplayPos(x, y, scaleFactor, this.posture);
    this.angle = -90;
    this.selected = false;
    this.is_on_mat = true;
    this.targetPosition = null;
    this.targetReached = false;
  }

  void display(float scaleFactor) {
    pushMatrix();  // Save the current transformation matrix
    fill(selected ? color(0, 255, 0) : color(255)); // Use green if selected, white otherwise
    if (!is_on_mat) {
      stroke(255, 0, 0); // Red border if the cube is not on the mat
    } else {
      stroke(0); // Black border if the cube is on the mat
    }
    rectMode(CENTER);

    translate(displayPosition.x, displayPosition.y);
    rotate(radians(angle + 90));

    // Draw cube body
    rect(0, 0, toioSize * scaleFactor, toioSize * scaleFactor);

    // Draw the equilateral triangle
    float triangleSide = toioSize * scaleFactor / 5;
    float triangleHeight = (float) (triangleSide * Math.sqrt(3) / 2); // Height of the equilateral triangle
    fill(0);
    beginShape();
    vertex(0, -toioSize * scaleFactor / 2); // Top center of the triangle
    vertex(-triangleSide / 2, -toioSize * scaleFactor / 2 + triangleHeight); // Bottom left of the triangle
    vertex(triangleSide / 2, -toioSize * scaleFactor / 2 + triangleHeight); // Bottom right of the triangle
    endShape(CLOSE);

    fill(0);
    textAlign(CENTER, CENTER);
    textSize(12.0 * scaleFactor);
    text(id, 0, 0);

    // Draw the battery indicator
    float batterySquareSize = toioSize * scaleFactor / 10;
    float batteryYOffset = toioSize * scaleFactor / 2 - batterySquareSize / 2;
    int numSquares = battery / 10;

    for (int i = 0; i < 10; i++) {
        if (i < numSquares) {
            if (battery >= 80) {
                fill(0, 255, 0); // Green
            } else if (battery >= 40) {
                fill(255, 255, 0); // Yellow
            } else {
                fill(255, 0, 0); // Red
            }
        } else {
            fill(255);
        }
        rectMode(CENTER);
        noStroke();
        rect((i - 5 + 0.5) * batterySquareSize, batteryYOffset, batterySquareSize, batterySquareSize);
    }
    rectMode(CENTER);
    stroke(0);
    noFill();
    rect((0) * batterySquareSize, batteryYOffset, toioSize * scaleFactor, batterySquareSize);



    popMatrix();  // Restore the original transformation matrix

    // Draw the target line
    if (hasTarget()) {
      stroke(255, 0, 0);
      line(displayPosition.x, displayPosition.y, targetPosition.x, targetPosition.y);
    }
  }

  void setTargetPosition(PVector target) {
    this.targetPosition = target;
    this.targetReached = false;
  }

  void reachTarget() {
    this.targetReached = true;
  }

  boolean hasTarget() {
    return targetPosition != null && !targetReached;
  }

  boolean isInside(PVector start, PVector end) {
    return displayPosition.x > min(start.x, end.x) && displayPosition.x < max(start.x, end.x) &&
           displayPosition.y > min(start.y, end.y) && displayPosition.y < max(start.y, end.y);
  }

  void moveTo(float x, float y) {
    this.matPosition.set(x, y);
    int send_x = (int)x;
    int send_y = (int)y;
    // Send move command to the server
    OscMessage msg = new OscMessage("/cube/" + this.id + "/move");
    msg.add(send_x);
    msg.add(send_y);
    msg.add(50); // speed
    NetAddress serverAddress = getServerAddressForCube(this.id);
    if (serverAddress != null) {
        oscP5.send(msg, serverAddress);
    }
  }

  void moveToAngle(float x, float y, float angle) {
    this.matPosition.set(x, y);
    int send_x = (int)x;
    int send_y = (int)y;
    int send_angle = (int)angle;
    // Send move command to the server
    OscMessage msg = new OscMessage("/cube/" + this.id + "/move");
    msg.add(send_x);
    msg.add(send_y);
    msg.add(send_angle);
    msg.add(50); // speed
    NetAddress serverAddress = getServerAddressForCube(this.id);
    if (serverAddress != null) {
        oscP5.send(msg, serverAddress);
    }
  }

  void moveToP(float x, float y, float angle) {
    this.matPosition.set(x, y);
    int send_x = (int)x;
    int send_y = (int)y;
    int send_angle = (int)angle;
    // Send move command to the server
    OscMessage msg = new OscMessage("/cube/" + this.id + "/p_move");
    msg.add(send_x);
    msg.add(send_y);
    if (angle != 1000) msg.add(send_angle);
    NetAddress serverAddress = getServerAddressForCube(this.id);
    if (serverAddress != null) {
        oscP5.send(msg, serverAddress);
    }
  }

  void moveRaw(int leftSpeed, int rightSpeed, int duration) {
  OscMessage msg = new OscMessage("/cube/" + this.id + "/motor");
  msg.add(leftSpeed);
  msg.add(rightSpeed);
  msg.add(duration);
  NetAddress serverAddress = getServerAddressForCube(this.id); // Resolve the correct server
  if (serverAddress != null) {
    oscP5.send(msg, serverAddress);
    }
  }

  void updatePosition(float x, float y, float angle) {
    this.matPosition.set(x, y);

    // Find the corresponding mat based on position and posture
    toioMat currentMat = null;
    for (toioMat mat : toioMats.mats) {
      if (mat.id != 0 && mat.id != 13) { // Ignore mats 0 and 13
        // Check if cube is on a wall (posture 3-6) and mat is a wall
        boolean isWallMatch = (this.posture >= 3 && mat.posture == 3);
        // Check if cube posture matches floor or ceiling exactly
        boolean isFloorCelingMatch = (this.posture < 3 && this.posture == mat.posture);
        if ((isWallMatch || isFloorCelingMatch) && mat.containsPoint(x, y)) {
          currentMat = mat;
          break;
        }
      }
    }

    if (currentMat != null) {
      // Convert coordinates using the found mat's coordinate system
      this.displayPosition = currentMat.matToDisplayCoords(x, y, scaleFactor);
      // Adjust the angle based on the mat's rotation
      this.angle = angle + currentMat.rotation;
      this.is_on_mat = true;
      // Update surface based on mat ID and posture
      switch (currentMat.posture) {
        case 1: // Floor
          this.surface = "F";
          break;
        case 2: // Ceiling
          this.surface = "C";
          break;
        case 3: // Wall
          if (currentMat.id == 1 || currentMat.id == 5) {
            this.surface = "LW"; // Left Wall
          } else if (currentMat.id == 2 || currentMat.id == 3 || currentMat.id == 6 || currentMat.id == 7) {
            this.surface = "FW"; // Front Wall
          } else if (currentMat.id == 4 || currentMat.id == 8) {
            this.surface = "RW"; // Right Wall
          }
          break;
      }
    } else {
      this.is_on_mat = false;
    }
  }

  void updatePosture(int posture) {
    this.posture = posture;
  }

  void updateCubeLED() {
    String newSurface = this.surface;
    if (!this.surface.equals(this.previousSurface)) {
      int r = 0, g = 0, b = 0;

      switch (newSurface) {
        case "F": // Floor
          r = 255; g = 0; b = 0; // Red
          break;
        case "FW": // Front Wall
          r = 0; g = 255; b = 0; // Green
          break;
        case "LW": // Left Wall
          r = 0; g = 0; b = 255; // Blue
          break;
        case "RW": // Right Wall
          r = 255; g = 255; b = 0; // Yellow
          break;
        case "C": // Ceiling
          r = 255; g = 0; b = 255; // Magenta
          break;
      }

      OscMessage msg = new OscMessage("/cube/" + this.id + "/led");
      msg.add(r);
      msg.add(g);
      msg.add(b);
      msg.add(0); // Duration in milliseconds
      NetAddress serverAddress = getServerAddressForCube(this.id);
      if (serverAddress != null) {
        oscP5.send(msg, serverAddress);
      }

      this.previousSurface = newSurface; // Update the previous surface
    }
  }
}
