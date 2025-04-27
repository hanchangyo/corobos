import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.ArrayList;
import java.util.HashMap;

OscP5 oscP5;

ArrayList<Server> servers = new ArrayList<Server>();;
ArrayList<toioCube> toioCubes = new ArrayList<>();
ArrayList<toioCube> selectedCubes = new ArrayList<>();
matList toioMats = new matList();

PVector matTopLeft;
PVector matBottomRight;
float toioSize = 32.0 / 1.377; // convert mm to mat coordinates
boolean dragging = false;
PVector dragStart, dragEnd;
boolean draggingRight = false;
PVector rightDragStart, rightDragEnd;

boolean shiftDragging = false;
PVector shiftDragStart = null;
PVector lastOffset = new PVector(0, 0);

float scaleFactor = 0.7; // Adjusted scale factor to visualize all mats clearly on the screen

PVector matOffset = new PVector(0, 0); // Default offset for the mat
float matRotation = 0; // Default rotation for the mat

ControlP5 cp5;
Textfield cubeIdInput;
Button connectButton;
Button disconnectButton;
Button connectAllButton;
Button disconnectAllButton;
Button playButton;
Button stopButton; // Stop button
boolean stopTransitions = false; // Flag to stop transitions
DropdownList currentSurfaceDropdown;
DropdownList targetSurfaceDropdown;

// Define transition positions as a map
HashMap<String, PVector[]> transitionPositions = new HashMap<>();

// Define groups and transitions
HashMap<Integer, int[]> groups = new HashMap<>();
HashMap<Integer, String[]> groupTransitions = new HashMap<>();

// Declare timeoutCounter as a class-level variable
private int timeoutCounter;

void initializeMats() {
  toioMats = new matList();
  PVector screenCenter = new PVector(width / 2, height / 2);
  PVector offset = new PVector(
    screenCenter.x - (toioMats.matHeight / 2) * scaleFactor,
    screenCenter.y + (toioMats.matWidth / 2) * scaleFactor
  );
  println("offset: " + offset);

  // front wall
  toioMats.addMat(new toioMat(2, PVector.add(offset, new PVector(toioMats.matHeight * 0 * scaleFactor, toioMats.matWidth * 0 * scaleFactor)), -90, 3));
  toioMats.addMat(new toioMat(3, PVector.add(offset, new PVector(toioMats.matHeight * 1 * scaleFactor, toioMats.matWidth * 0 * scaleFactor)), -90, 3));
  toioMats.addMat(new toioMat(6, PVector.add(offset, new PVector(toioMats.matHeight * 0 * scaleFactor, toioMats.matWidth * -1 * scaleFactor)), -90, 3));
  toioMats.addMat(new toioMat(7, PVector.add(offset, new PVector(toioMats.matHeight * 1 * scaleFactor, toioMats.matWidth * -1 * scaleFactor)), -90, 3));

  // left wall
  toioMats.addMat(new toioMat(1, PVector.add(offset, new PVector(toioMats.matHeight * -1 * scaleFactor, toioMats.matWidth * 0 * scaleFactor)), -90, 3));
  toioMats.addMat(new toioMat(5, PVector.add(offset, new PVector(toioMats.matHeight * -1 * scaleFactor, toioMats.matWidth * -1 * scaleFactor)), -90, 3));
//   toioMats.addMat(new toioMat(9, PVector.add(offset, new PVector(toioMats.matHeight * -2 * scaleFactor, toioMats.matWidth * 0 * scaleFactor)), -90, 3));
//   toioMats.addMat(new toioMat(10, PVector.add(offset, new PVector(toioMats.matHeight * -2 * scaleFactor, toioMats.matWidth * -1 * scaleFactor)), -90, 3));

  // right wall
  toioMats.addMat(new toioMat(4, PVector.add(offset, new PVector(toioMats.matHeight * 2 * scaleFactor, toioMats.matWidth * 0 * scaleFactor)), -90, 3));
  toioMats.addMat(new toioMat(8, PVector.add(offset, new PVector(toioMats.matHeight * 2 * scaleFactor, toioMats.matWidth * -1 * scaleFactor)), -90, 3));
//   toioMats.addMat(new toioMat(11, PVector.add(offset, new PVector(toioMats.matHeight * 3 * scaleFactor, toioMats.matWidth * 0 * scaleFactor)), -90, 3));
//   toioMats.addMat(new toioMat(12, PVector.add(offset, new PVector(toioMats.matHeight * 3 * scaleFactor, toioMats.matWidth * -1 * scaleFactor)), -90, 3));

  // ceiling
  toioMats.addMat(new toioMat(11, PVector.add(offset, new PVector(toioMats.matHeight * 0 * scaleFactor, toioMats.matWidth * -2 * scaleFactor)), -90, 2));
  toioMats.addMat(new toioMat(12, PVector.add(offset, new PVector(toioMats.matHeight * 1 * scaleFactor, toioMats.matWidth * -2 * scaleFactor)), -90, 2));

  // floor
  toioMats.addMat(new toioMat(9, PVector.add(offset, new PVector(toioMats.matHeight * 0 * scaleFactor, toioMats.matWidth * 1 * scaleFactor)), -90, 1));
  toioMats.addMat(new toioMat(10, PVector.add(offset, new PVector(toioMats.matHeight * 1 * scaleFactor, toioMats.matWidth * 1 * scaleFactor)), -90, 1));
}

void setup() {
  size(1000, 1000);
  initializeMats();

  toioMats.printBounds();

  oscP5 = new OscP5(this, 8001);  // Set OSC receiver port to 8001

  // Initialize servers
//   servers.add(new Server("127.0.0.1", 8000, new int[]{1,2,3,4}));
//   servers.add(new Server("127.0.0.1", 8000, new int[]{1}));
//   servers.add(new Server("192.168.11.3", 8000, new int[]{5,6,7,8}));
//   servers.add(new Server("192.168.11.4", 8000, new int[]{9,10,11,12}));
//   servers.add(new Server("192.168.11.5", 8000, new int[]{13,14,15,16}));

  // servers.add(new Server("192.168.11.3", 8000, new int[]{14, 15}));
//   servers.add(new Server("192.168.11.4", 8000, new int[]{7,8,9,10,11}));
//   servers.add(new Server("192.168.11.5", 8000, new int[]{12,13,14,15,16}));
  servers.add(new Server("192.168.11.3", 8000, new int[]{1,2,3,4,5,6}));
  servers.add(new Server("192.168.11.4", 8000, new int[]{7,8,9,10,11}));
  servers.add(new Server("192.168.11.5", 8000, new int[]{12,13,14,15,16}));


  cp5 = new ControlP5(this);

  cubeIdInput = cp5.addTextfield("cube_id")
                   .setPosition(20, 20)
                   .setSize(100, 30)
                   .setFocus(true)
                   .setColor(color(255, 0, 0));

  connectButton = cp5.addButton("connect_button")
                     .setLabel("Connect")
                     .setPosition(130, 20)
                     .setSize(80, 30)
                     .onClick(new CallbackListener() {
                       public void controlEvent(CallbackEvent event) {
                         connectCube();
                       }
                     });

  disconnectButton = cp5.addButton("disconnect_button")
                        .setLabel("Disconnect")
                        .setPosition(220, 20)
                        .setSize(80, 30)
                        .onClick(new CallbackListener() {
                          public void controlEvent(CallbackEvent event) {
                            disconnectCube();
                          }
                        });

  connectAllButton = cp5.addButton("connect_all_button")
                        .setLabel("Connect All")
                        .setPosition(width - 200, 20) // Adjusted position to upper right corner
                        .setSize(80, 30)
                        .onClick(new CallbackListener() {
                          public void controlEvent(CallbackEvent event) {
                            connectAllCubes();
                          }
                        });

  disconnectAllButton = cp5.addButton("diconnect_all_button")
                        .setLabel("Disconnect All")
                        .setPosition(width - 100, 20) // Adjusted position to upper right corner
                        .setSize(80, 30)
                        .onClick(new CallbackListener() {
                          public void controlEvent(CallbackEvent event) {
                            disconnectAllCubes();
                          }
                        });

  stopButton = cp5.addButton("stop_button")
                  .setLabel("Stop")
                  .setPosition(420, 20)
                  .setSize(80, 30)
                  .onClick(new CallbackListener() {
                    public void controlEvent(CallbackEvent event) {
                      stopTransitions = true;
                      println("All transitions stopped.");
                    }
                  });

  // Initialize groups and transitions
  groups.put(1, new int[]{1, 2, 3, 4});
  groups.put(2, new int[]{5, 6, 7, 8});
  groups.put(3, new int[]{9, 10, 11, 12});
  groups.put(4, new int[]{13, 14, 15, 16});
  groupTransitions.put(1, new String[]{"F2FW", "FW2LW", "LW2F"});
  groupTransitions.put(2, new String[]{"F2RW", "RW2FW", "FW2F"});
  groupTransitions.put(3, new String[]{"FW2C", "C2LW", "LW2FW"});
  groupTransitions.put(4, new String[]{"FW2RW", "RW2C", "C2FW"});

//   currentSurfaceDropdown = cp5.addDropdownList("current_surface")
//                               .setPosition(420, 20)
//                               .setSize(100, 100)
//                               .setBarHeight(20)
//                               .setItemHeight(20)
//                               .addItems(new String[]{"F", "FW", "LW", "RW", "C"});

//   targetSurfaceDropdown = cp5.addDropdownList("target_surface")
//                               .setPosition(540, 20)
//                               .setSize(100, 100)
//                               .setBarHeight(20)
//                               .setItemHeight(20)
//                               .addItems(new String[]{"F", "FW", "LW", "RW", "C"});

  playButton = cp5.addButton("play_button")
                  .setLabel("Play")
                  .setPosition(320, 20)
                  .setSize(80, 30)
                  .onClick(new CallbackListener() {
                    public void controlEvent(CallbackEvent event) {
                      for (int groupId : groups.keySet()) {
                        new Thread(() -> {
                          String[] transitions = groupTransitions.get(groupId);
                          int[] cubeIds = groups.get(groupId);

                        while (!stopTransitions) {
                          for (String transition : transitions) {
                            if (stopTransitions) break;

                            String originSurface = transition.split("2")[0];
                            ArrayList<toioCube> availableCubes = findAvailableCubes(cubeIds, originSurface);

                            // Check if there are at least two available cubes
                            if (availableCubes.size() < 2) {
                                // println("Not enough cubes available for transition: " + "origin surace: " + originSurface + ", cubes: " + availableCubes.size());
                                continue; // Skip this transition if not enough cubes
                            }

                            // Sort available cubes by distance to the closest transition position
                            availableCubes.sort((cube1, cube2) -> {
                                PVector[] positions = transitionPositions.get(transition);
                                if (positions == null) return 0;

                                PVector TPosition = positions[0];
                                float distance1 = dist(cube1.matPosition.x, cube1.matPosition.y, TPosition.x, TPosition.y);
                                float distance2 = dist(cube2.matPosition.x, cube2.matPosition.y, TPosition.x, TPosition.y);

                                // print cube numbers and distances
                                println("Cube " + cube1.id + " distance: " + distance1);
                                println("Cube " + cube2.id + " distance: " + distance2);

                                return Float.compare(distance1, distance2);
                            });

                            // Set the closest cube as T and the second closest as H
                            toioCube T = availableCubes.get(0);
                            toioCube H = availableCubes.get(1);

                            startTransition(transition, T, H);
                            delay(2000); // Wait before the next transition
                          }
                        }
                      }).start();
                    }
                  }
            });

  oscP5.plug(this, "updateCubePosition", "/cube/*/pos");
  oscP5.plug(this, "updateCubePosture", "/cube/*/posture");

  // Initialize transition positions
  transitionPositions.put("F2FW", new PVector[]{
      new PVector(900, 200, 0), // T
      new PVector(687, 200, 0),  // H before transition
      new PVector(845, 200, 0),  // H
      new PVector(226, 438, 0) // T after transition
  });
  transitionPositions.put("F2LW", new PVector[]{
      new PVector(790, 80, 270),
      new PVector(790, 135, 270),
      new PVector(270, 66, 0)
  });
  transitionPositions.put("F2RW", new PVector[]{
      new PVector(790, 415, 90),
      new PVector(790, 290, 90),
      new PVector(790, 360, 90),
      new PVector(236, 850, 0)
  });
  transitionPositions.put("FW2F", new PVector[]{
      new PVector(75, 520, 180),
      new PVector(280, 520, 180),
      new PVector(130, 520, 180),
      new PVector(717, 283, 0)
  });
  transitionPositions.put("LW2F", new PVector[]{
      new PVector(75, 180, 180),
      new PVector(280, 180, 180),
      new PVector(130, 180, 180),
      new PVector(675, 150, 100)
  });
  transitionPositions.put("RW2F", new PVector[]{
      new PVector(80, 750, 180),
      new PVector(135, 750, 180),
      new PVector(780, 180, 100)
  });
  transitionPositions.put("FW2C", new PVector[]{
      new PVector(590, 420, 0),
      new PVector(400, 420, 0),
      new PVector(535, 420, 0),
      new PVector(882, 640, 0)
  });
  transitionPositions.put("LW2C", new PVector[]{
      new PVector(590, 80, 360),
      new PVector(535, 80, 360),
      new PVector(870, 600, 90)
  });
  transitionPositions.put("RW2C", new PVector[]{
      new PVector(590, 840, 0),
      new PVector(460, 840, 0),
      new PVector(535, 840, 0),
      new PVector(900, 733, 270)
  });
  transitionPositions.put("C2FW", new PVector[]{
      new PVector(695, 740, 180),
      new PVector(870, 740, 180),
      new PVector(750, 740, 180),
      new PVector(407, 520, 180)
  });
  transitionPositions.put("C2LW", new PVector[]{
      new PVector(750, 515, 270),
      new PVector(750, 630, 270),
      new PVector(750, 570, 270),
      new PVector(472, 67, 96)
  });
  transitionPositions.put("C2RW", new PVector[]{
      new PVector(700, 850, 90),
      new PVector(700, 795, 90),
      new PVector(455, 747, 127)
  });
  transitionPositions.put("LW2FW", new PVector[]{
      new PVector(430, 200, 90),
      new PVector(430, 80, 90),
      new PVector(430, 145, 90),
      new PVector(396, 414, 30)
  });
  transitionPositions.put("FW2LW", new PVector[]{
      new PVector(280, 290, 270),
      new PVector(280, 430, 270),
      new PVector(280, 345, 270),
      new PVector(292, 73, 210)
  });
  transitionPositions.put("FW2RW", new PVector[]{
      new PVector(395, 630, 90),
      new PVector(394, 500, 90),
      new PVector(395, 575, 90),
      new PVector(390, 864, 10)
  });
  transitionPositions.put("RW2FW", new PVector[]{
      new PVector(280, 730, 270),
      new PVector(280, 860, 270),
      new PVector(280, 785, 270),
      new PVector(240, 515, 140)
  });
}

void draw() {
  background(30);
  toioMats.display(scaleFactor);
  drawToioCubes();
  drawSelection();
  if (draggingRight && rightDragEnd != null) {
    drawArrow(rightDragStart, rightDragEnd);
  }

  // Update LEDs for all cubes
  updateAllCubeLEDs();
}

void drawToioCubes() {
  ArrayList<toioCube> toioCubesCopy = new ArrayList<toioCube>(toioCubes);
  for (toioCube cube : toioCubesCopy) {
    cube.display(scaleFactor);
  }
}

void drawSelection() {
  if (dragging) {
    rectMode(CORNER);
    noFill();
    stroke(0, 255, 0);
    rect(dragStart.x, dragStart.y, mouseX - dragStart.x, mouseY - dragStart.y);
  }

  if (!selectedCubes.isEmpty()) {
    PVector centroid = calculateCentroid(selectedCubes);
    fill(255, 0, 0, 100);
    noStroke();
    ellipse(centroid.x, centroid.y, toioSize * scaleFactor / 5, toioSize * scaleFactor / 5);
  }
}

void drawArrow(PVector start, PVector end) {
  stroke(255, 0, 0);
  line(start.x, start.y, end.x, end.y);

  float angle = atan2(end.y - start.y, end.x - start.x);
  float arrowSize = 10;

  pushMatrix();
  translate(end.x, end.y);
  rotate(angle);
  line(0, 0, -arrowSize, -arrowSize / 2);
  line(0, 0, -arrowSize, arrowSize / 2);
  popMatrix();
}

void mousePressed() {
  if (keyPressed && keyCodeIsShift()) {
    shiftDragging = true;
    shiftDragStart = new PVector(mouseX, mouseY);
    return;
  }

  if (mouseButton == LEFT) {
    dragStart = new PVector(mouseX, mouseY);
    dragging = true;
    println("mouseX: " + mouseX + " mouseY: " + mouseY);
    PVector matPos = convert2MatPos(mouseX, mouseY, scaleFactor);
    println("matX: " + matPos.x + " matY: " + matPos.y);
  } else if (mouseButton == RIGHT) {
    rightDragStart = new PVector(mouseX, mouseY);
    rightDragEnd = null;
    draggingRight = true;
  }
}

void mouseReleased() {
  if (shiftDragging) {
    shiftDragging = false;
    // Just store the final position relative to start
    lastOffset = PVector.sub(new PVector(mouseX, mouseY), shiftDragStart);
    shiftDragStart = null;
    return;
  }

  if (mouseButton == LEFT && dragging) {
    dragEnd = new PVector(mouseX, mouseY);
    selectCubes();
    dragging = false;
  } else if (mouseButton == RIGHT && draggingRight) {
    if (rightDragEnd == null) {
      moveCubes(mouseX, mouseY);
      // moveCubesP(rightDragStart.x, rightDragStart.y);
    } else {
      moveCubesWithAngle(rightDragStart.x, rightDragStart.y, calculateAngle(rightDragStart, rightDragEnd));
      // moveCubesPwithAngle(rightDragStart.x, rightDragStart.y, calculateAngle(rightDragStart, rightDragEnd));
    }
    draggingRight = false;
  }
}

void mouseDragged() {
  if (shiftDragging && shiftDragStart != null) {
    // Calculate the current drag delta from the start position
    PVector currentDelta = PVector.sub(new PVector(mouseX, mouseY), shiftDragStart);

    // Apply movement to all mats
    for (toioMat mat : toioMats.mats) {
      // Move relative to the last frame's position
      PVector previousPos = mat.position.copy();
      PVector newPos = PVector.add(previousPos, PVector.sub(currentDelta, lastOffset));
      mat.position = newPos;
    }

    // Store current delta for next frame comparison
    lastOffset = currentDelta;
  }

  if (draggingRight) {
    rightDragEnd = new PVector(mouseX, mouseY);
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  float newScaleFactor = scaleFactor - e * 0.1; // Subtract because up wheel should zoom in
  newScaleFactor = constrain(newScaleFactor, 0.1, 10.0); // Constrain the scale factor to a reasonable range

  if (newScaleFactor != scaleFactor) {
    scaleFactor = newScaleFactor;
    initializeMats(); // Reinitialize mats with new scale factor
  }
}

void selectCubes() {
  if (dragEnd == null || dragStart == null) return;

  if (!keyPressed || (keyPressed && !keyCodeIsShift())) {
    // Clear the selectedCubes list if shift is not pressed
    selectedCubes.clear();
  }

  for (toioCube cube : toioCubes) {
    if (cube.isInside(dragStart, dragEnd)) {
      if (!selectedCubes.contains(cube)) {
        selectedCubes.add(cube);
        cube.selected = true;
      }
    } else if (!keyPressed || (keyPressed && !keyCodeIsShift())) {
      cube.selected = false;
    }
  }
}

void keyPressed() {
  if (selectedCubes.isEmpty()) {
    return; // No cubes selected, do nothing
  }

  for (toioCube cube : selectedCubes) {
    if (key == CODED) {
      if (keyCode == UP) {
        // Move forward
        cube.moveRaw(115, 115, 500); // Speed: 115, Duration: 500ms
      } else if (keyCode == DOWN) {
        // Move backward
        cube.moveRaw(-115, -115, 500); // Speed: -115, Duration: 500ms
      } else if (keyCode == LEFT) {
        // Turn counter-clockwise
        cube.moveRaw(-30, 30, 300); // Left motor reverse, Right motor forward
      } else if (keyCode == RIGHT) {
        // Turn clockwise
        cube.moveRaw(30, -30, 300); // Left motor forward, Right motor reverse
      }
    }
  }
}

boolean keyCodeIsShift() {
  return key == CODED && keyCode == SHIFT;
}

void moveCubes(float targetX, float targetY) {
  PVector target = new PVector(targetX, targetY);
  PVector centroid = calculateCentroid(selectedCubes);
  PVector offset = PVector.sub(target, centroid);
  for (toioCube cube : selectedCubes) {
    PVector newPos = PVector.add(cube.displayPosition, offset);
    PVector matPos= convert2MatPos(newPos.x, newPos.y, scaleFactor);
    cube.setTargetPosition(newPos); // Set the target position
    cube.moveTo(matPos.x, matPos.y);
  }
}

float calculateAngle(PVector start, PVector end) {
  // Calculate the raw angle in screen coordinates
  float screenAngle = (degrees(atan2(end.y - start.y, end.x - start.x)) + 360) % 360;

  // Convert target position to find which mat it's on
  PVector matPos = convert2MatPos(end.x, end.y, scaleFactor);

  // Find the corresponding mat
  toioMat targetMat = null;
  for (toioMat mat : toioMats.mats) {
    if (mat.id != 0 && mat.id != 13 && mat.containsPoint(matPos.x, matPos.y)) {
      targetMat = mat;
      break;
    }
  }

  // If we found a mat, adjust the angle based on mat's rotation
  if (targetMat != null) {
    // Subtract the mat's rotation to get the angle relative to the mat
    float matRelativeAngle = (screenAngle - targetMat.rotation + 360) % 360;
    println("Screen angle: " + screenAngle + ", Mat rotation: " + targetMat.rotation + ", Relative angle: " + matRelativeAngle);
    return matRelativeAngle;
  }

  println("Screen angle: " + screenAngle);
  return screenAngle;
}

void moveCubesWithAngle(float targetX, float targetY, float angle) {
  PVector target = new PVector(targetX, targetY);
  PVector centroid = calculateCentroid(selectedCubes);
  PVector offset = PVector.sub(target, centroid);

  // Convert target position to mat coordinates to find the target mat
  PVector matPos = convert2MatPos(targetX, targetY, scaleFactor);
  toioMat targetMat = null;
  for (toioMat mat : toioMats.mats) {
    if (mat.id != 0 && mat.id != 13 && mat.containsPoint(matPos.x, matPos.y)) {
      targetMat = mat;
      break;
    }
  }

  for (toioCube cube : selectedCubes) {
    PVector newPos = PVector.add(cube.displayPosition, offset);
    PVector cubeMatPos = convert2MatPos(newPos.x, newPos.y, scaleFactor);

    // If we found the target mat, use the mat-relative angle
    if (targetMat != null) {
      cube.moveToAngle(cubeMatPos.x, cubeMatPos.y, angle);
    } else {
      // Fallback to global coordinates if no mat found
      cube.moveToAngle(cubeMatPos.x, cubeMatPos.y, angle);
    }
  }
}

void moveCubesP(float targetX, float targetY) {
  PVector target = new PVector(targetX, targetY);
  PVector centroid = calculateCentroid(selectedCubes);
  PVector offset = PVector.sub(target, centroid);

  // Convert target position to mat coordinates to find the target mat
  PVector matPos = convert2MatPos(targetX, targetY, scaleFactor);
  toioMat targetMat = null;
  for (toioMat mat : toioMats.mats) {
    if (mat.id != 13 && mat.containsPoint(matPos.x, matPos.y)) {
      targetMat = mat;
      break;
    }
  }

  for (toioCube cube : selectedCubes) {
    PVector newPos = PVector.add(cube.displayPosition, offset);
    PVector cubeMatPos = convert2MatPos(newPos.x, newPos.y, scaleFactor);

    // If we found the target mat, use the mat-relative angle
    if (targetMat != null) {
      cube.moveToP(cubeMatPos.x, cubeMatPos.y, 1000);
    } else {
      // Fallback to global coordinates if no mat found
      cube.moveToP(cubeMatPos.x, cubeMatPos.y, 1000);
    }
  }
}

void moveCubesPwithAngle(float targetX, float targetY, float angle) {
  PVector target = new PVector(targetX, targetY);
  PVector centroid = calculateCentroid(selectedCubes);
  PVector offset = PVector.sub(target, centroid);

  // Convert target position to mat coordinates to find the target mat
  PVector matPos = convert2MatPos(targetX, targetY, scaleFactor);
  toioMat targetMat = null;
  for (toioMat mat : toioMats.mats) {
    if (mat.id != 13 && mat.containsPoint(matPos.x, matPos.y)) {
      targetMat = mat;
      break;
    }
  }

  for (toioCube cube : selectedCubes) {
    PVector newPos = PVector.add(cube.displayPosition, offset);
    PVector cubeMatPos = convert2MatPos(newPos.x, newPos.y, scaleFactor);

    // If we found the target mat, use the mat-relative angle
    if (targetMat != null) {
      cube.moveToP(cubeMatPos.x, cubeMatPos.y, angle);
    } else {
      // Fallback to global coordinates if no mat found
      cube.moveToP(cubeMatPos.x, cubeMatPos.y, angle);
    }
  }
}

PVector calculateCentroid(ArrayList<toioCube> cubes) {
  PVector centroid = new PVector(0, 0);
  for (toioCube cube : cubes) {
    centroid.add(cube.displayPosition);
  }
  centroid.div(cubes.size());
  return centroid;
}

void connectCube() {
  int cubeId = int(cubeIdInput.getText());
  OscMessage msg = new OscMessage("/cube/" + cubeId + "/connect");
  NetAddress serverAddress = getServerAddressForCube(cubeId);
  if (serverAddress != null) {
    oscP5.send(msg, serverAddress);
  }
}

void connectAllCubes()
{
  for (Server server : servers)
  {
    for (int cubeId : server.cubeIds)
    {
        OscMessage msg = new OscMessage("/cube/" + cubeId + "/connect");
        NetAddress serverAddress = server.getAddress();
        if (serverAddress != null) {
            oscP5.send(msg, serverAddress);
            delay(500); // Add a small delay to avoid overwhelming the server
        }
    }
  }
}

void disconnectCube() {
  int cubeId = int(cubeIdInput.getText());
  OscMessage msg = new OscMessage("/cube/" + cubeId + "/disconnect");
  NetAddress serverAddress = getServerAddressForCube(cubeId);
  if (serverAddress != null) {
    oscP5.send(msg, serverAddress);
  }
  toioCubes.removeIf(cube -> cube.id == cubeId);
}

void disconnectAllCubes()
{
  for (Server server : servers)
  {
    for (int cubeId : server.cubeIds)
    {
        OscMessage msg = new OscMessage("/cube/" + cubeId + "/disconnect");
        NetAddress serverAddress = server.getAddress();
        if (serverAddress != null) {
            oscP5.send(msg, serverAddress);
        }
        toioCubes.removeIf(cube -> cube.id == cubeId);
    }
  }
}

NetAddress getServerAddressForCube(int cubeId) {
  for (Server server : servers) {
    if (server.managesCube(cubeId)) {
      return server.getAddress();
    }
  }
  return null;
}

boolean checkCubeAddrPattern(OscMessage theOscMessage, String pattern) {
  String addrPattern = theOscMessage.addrPattern();
  String[] parts = addrPattern.split("/");
  if (parts.length < 3) {
    return false;
  }
  String cubeId = parts[2];
  return addrPattern.equals("/cube/" + cubeId + "/" + pattern);
}

void oscEvent(OscMessage theOscMessage) {
  // print("### received an osc message.");
  // print(" addrpattern: " + theOscMessage.addrPattern());
  // println(" typetag: " + theOscMessage.typetag());

  if (checkCubeAddrPattern(theOscMessage, "pos") && theOscMessage.checkTypetag("iii")) {
    String[] parts = theOscMessage.addrPattern().split("/");
    int cubeId = int(parts[2]); // Extract cube ID from the message address
    int x = theOscMessage.get(0).intValue();
    int y = theOscMessage.get(1).intValue();
    int angle = theOscMessage.get(2).intValue();
    for (toioCube cube : toioCubes) {
      if (cube.id == cubeId) {
        if (x == -1 && y == -1 && angle == -1) {
          cube.is_on_mat = false;
        } else {
          cube.updatePosition(x, y, angle);
          cube.is_on_mat = true;
        }
        break;
      }
    }
  } else if (checkCubeAddrPattern(theOscMessage, "move_goal") && theOscMessage.checkTypetag("i")) {
    String[] parts = theOscMessage.addrPattern().split("/");
    int cubeId = int(parts[2]); // Extract cube ID from the message address
    boolean goalReached = theOscMessage.get(0).intValue() == 1;
    for (toioCube cube : toioCubes) {
      if (cube.id == cubeId) {
        if (goalReached) {
          cube.reachTarget();
        }
        break;
      }
    }
  } else if (checkCubeAddrPattern(theOscMessage, "connect") && theOscMessage.checkTypetag("i")) { // Add this block
    String[] parts = theOscMessage.addrPattern().split("/");
    int cubeId = int(parts[2]); // Extract cube ID from the message address
    boolean connected = theOscMessage.get(0).intValue() == 1;
    if (connected) {
      // Initialize the cube in the bottom right corner of the mat
      toioCube newCube = new toioCube(cubeId, toioMats.matBottomRight.x, toioMats.matBottomRight.y + toioSize * 2);
      toioCubes.add(newCube);
    }
  } else if (checkCubeAddrPattern(theOscMessage, "disconnect") && theOscMessage.checkTypetag("i")) { // Add this block
    String[] parts = theOscMessage.addrPattern().split("/");
    int cubeId = int(parts[2]); // Extract cube ID from the message address
    boolean disconnected = theOscMessage.get(0).intValue() == 1;
    if (disconnected) {
      toioCubes.removeIf(cube -> cube.id == cubeId);
    }
  } else if (checkCubeAddrPattern(theOscMessage, "battery") && theOscMessage.checkTypetag("i")) { // Add this block
    String[] parts = theOscMessage.addrPattern().split("/");
    int cubeId = int(parts[2]); // Extract cube ID from the message address
    int battery = theOscMessage.get(0).intValue();
    for (toioCube cube : toioCubes) {
      if (cube.id == cubeId) {
        cube.battery = battery;
        break;
      }
    }
  } else if (checkCubeAddrPattern(theOscMessage, "posture") && theOscMessage.checkTypetag("i")) {
    String[] parts = theOscMessage.addrPattern().split("/");
    int cubeId = int(parts[2]); // Extract cube ID from the message address
    int posture = theOscMessage.get(0).intValue();
    println("Cube " + cubeId + " posture updated to: " + posture);
    for (toioCube cube : toioCubes) {
      if (cube.id == cubeId) {
        cube.updatePosture(posture);
        break;
      }
    }
  }
}

// Converts screen coordinates to mat coordinates based on the scale factor, rotation and the mat's offset
PVector convert2MatPos(float x, float y, float scaleFactor) {
    PVector screenCenter = new PVector(width / 2, height / 2);

    // Try to find which mat contains this screen position
    for (toioMat mat : toioMats.mats) {
        if (mat.id == 0 || mat.id == 13) continue; // Skip mats 0 and 13

        // Convert screen coordinates to mat's local coordinates
        float dx = x - mat.position.x;
        float dy = y - mat.position.y;

        // Rotate back by mat's rotation
        float angle = radians(-mat.rotation);
        float localX = dx * cos(angle) - dy * sin(angle);
        float localY = dx * sin(angle) + dy * cos(angle);

        // Scale down to mat coordinate system
        localX = localX / scaleFactor;
        localY = localY / scaleFactor;

        // Add mat's coordinate offset
        float matWidth = mat.matBottomRight.x - mat.matTopLeft.x;
        float matHeight = mat.matBottomRight.y - mat.matTopLeft.y;
        localX += mat.matTopLeft.x + matWidth/2;
        localY += mat.matTopLeft.y + matHeight/2;

        // Check if the point is within this mat's bounds
        if (mat.containsPoint(localX, localY)) {
            println("Found mat: " + mat.id + " at converted position: " + localX + ", " + localY);
            return new PVector(localX, localY);
        }
    }

    // If no mat found, return the global coordinate conversion (fallback)
    float dx = x - screenCenter.x;
    float dy = y - screenCenter.y;
    float angle = radians(-matRotation);
    float rotatedX = dx * cos(angle) - dy * sin(angle);
    float rotatedY = dx * sin(angle) + dy * cos(angle);

    float matX = rotatedX / scaleFactor + toioMats.matTopLeft.x;
    float matY = rotatedY / scaleFactor + toioMats.matTopLeft.y;

    return new PVector(matX, matY);
}

PVector convert2DisplayPos(float matX, float matY, float scaleFactor, int posture) {
    // Find the corresponding mat based on coordinates and posture
    toioMat targetMat = null;
    for (toioMat mat : toioMats.mats) {
        if (mat.id != 0 && mat.id != 13) { // Ignore mats 0 and 13
            // Check if cube is on a wall (posture 3-6) and mat is a wall
            boolean isWallMatch = (posture >= 3 && mat.posture == 3);
            // Check if cube posture matches floor or ceiling exactly
            boolean isExactMatch = (posture < 3 && posture == mat.posture);

            if ((isWallMatch || isExactMatch) && mat.containsPoint(matX, matY)) {
                targetMat = mat;
                break;
            }
        }
    }

    if (targetMat != null) {
        return targetMat.matToDisplayCoords(matX, matY, scaleFactor);
    }

    // Fallback to old conversion if no matching mat is found
    PVector screenCenter = new PVector(width / 2, height / 2);

    float dx = (matX - toioMats.matTopLeft.x) * scaleFactor;
    float dy = (matY - toioMats.matTopLeft.y) * scaleFactor;

    float angle = radians(matRotation);
    float rotatedX = dx * cos(angle) - dy * sin(angle);
    float rotatedY = dx * sin(angle) + dy * cos(angle);

    return new PVector(rotatedX + screenCenter.x, rotatedY + screenCenter.y);
}

// Function to find available cubes in a group on a specific surface
ArrayList<toioCube> findAvailableCubes(int[] cubeIds, String surface) {
    ArrayList<toioCube> availableCubes = new ArrayList<>();
    for (int cubeId : cubeIds) {
        for (toioCube cube : toioCubes) {
            if (cube.id == cubeId && cube.surface.equals(surface) && !cube.isBusy) {
                availableCubes.add(cube);
            }
        }
    }
    return availableCubes;
}

// Modify startTransition to accept specific cubes
void startTransition(String transitionKey, toioCube T, toioCube H) {
    T.isBusy = true;
    H.isBusy = true;

    PVector[] positions = transitionPositions.get(transitionKey);
    if (positions == null) {
        println("Invalid transition key: " + transitionKey);
        T.isBusy = false;
        H.isBusy = false;
        return;
    }

    PVector TPosition = positions[0];
    PVector HBeforePosition = positions[1];
    PVector HPosition = positions[2];
    PVector TFinalPosition = positions[3];

    T.targetReached = false; // reset target
    T.moveToAngle(TPosition.x, TPosition.y, TPosition.z);
    println("T " + T.id + " started to move to target position.");

    timeoutCounter = 0;
    int maxTimeout = 50; // Timeout after 5 seconds (50 * 100ms)

    while (!T.targetReached && timeoutCounter < maxTimeout) {
        delay(100); // Check every 100ms
        timeoutCounter++;
    }

    if (timeoutCounter >= maxTimeout) {
        println("T " + T.id + " failed to reach target position within timeout.");
        T.isBusy = false;
        H.isBusy = false;
        return;
    }

    println("T " + T.id + " reached target position.");

    H.targetReached = false; // reset target
    H.moveToAngle(HBeforePosition.x, HBeforePosition.y, HBeforePosition.z);
    println("H " + H.id + " started to move to before transition position.");

    timeoutCounter = 0;
    while (!H.targetReached && timeoutCounter < maxTimeout) {
        delay(100); // Check every 100ms
        timeoutCounter++;
    }

    if (timeoutCounter >= maxTimeout) {
        println("H " + H.id + " failed to reach target position within timeout.");
        T.isBusy = false;
        H.isBusy = false;
        return;
    }

    println("H " + H.id + " reached before transition position.");

    H.targetReached = false; // reset target
    H.moveToAngle(HPosition.x, HPosition.y, HPosition.z);
    println("H " + H.id + " started to move to transition position.");

    timeoutCounter = 0;
    while (!H.targetReached && timeoutCounter < maxTimeout) {
        delay(100); // Check every 100ms
        timeoutCounter++;
    }

    if (timeoutCounter >= maxTimeout) {
        println("H " + H.id + " failed to reach target position within timeout.");
        T.isBusy = false;
        H.isBusy = false;
        return;
    }

    println("H " + H.id + " reached target position.");


    T.moveRaw(115, 115, 500); // Maximum motor speed is 115
    if (transitionKey.equals("LW2FW") || transitionKey.equals("FW2RW")) {
        H.moveRaw(115, 115, 100);
        delay(100);
        H.moveRaw(20, 115, 2000); // H's motor speed for LW2FW and FW2RW
    } else if (transitionKey.equals("FW2LW") || transitionKey.equals("RW2FW")) {
        H.moveRaw(115, 115, 100);
        delay(100);
        H.moveRaw(115, 20, 2000); // H's motor speed for FW2LW and RW2FW
    } else {
        H.moveRaw(115, 115, 700); // Default motor speed
    }

    delay(2000);
    T.moveRaw(50, 50, 100); // Move T forward
    H.moveRaw(-50, -50, 500); // Move H backward

    new Thread(() -> {
        timeoutCounter = 0;
        while (!T.surface.equals(transitionKey.split("2")[1]) && timeoutCounter < maxTimeout) {
            delay(100); // Check every 100ms
            timeoutCounter++;
        }

        if (timeoutCounter >= maxTimeout) {
            println("T " + T.id + " failed to transition to the target surface within timeout.");
            T.isBusy = false;
            H.isBusy = false;
            return;
        }

        println("T " + T.id + " successfully transitioned to the target surface.");

        // Move T to the final position
        T.targetReached = false; // reset target
        T.moveToAngle(TFinalPosition.x, TFinalPosition.y, TFinalPosition.z);

        new Thread(() -> {
            timeoutCounter = 0;
            while (!T.targetReached && timeoutCounter < maxTimeout) {
                delay(100); // Check every 100ms
                timeoutCounter++;
            }

            if (timeoutCounter >= maxTimeout) {
                println("T " + T.id + " failed to reach final position within timeout.");
                T.isBusy = false;
                H.isBusy = false;
                return;
            }

            println("T " + T.id + " reached final position.");
            T.isBusy = false;
            H.isBusy = false;
        }).start();
    }).start();
}

void updateAllCubeLEDs() {
  for (toioCube cube : toioCubes) {
    cube.updateCubeLED();
  }
}
