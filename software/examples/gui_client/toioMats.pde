class matList {
    ArrayList<toioMat> mats;
    float matWidth;
    float matHeight;
    PVector matTopLeft;
    PVector matBottomRight;

    matList() {
        this.mats = new ArrayList<toioMat>();
        this.matWidth = 305;
        this.matHeight = 215;
        this.matTopLeft = new PVector(Float.MAX_VALUE, Float.MAX_VALUE);
        this.matBottomRight = new PVector(Float.MIN_VALUE, Float.MIN_VALUE);
    }

    void addMat(toioMat mat) {
        this.mats.add(mat);

        // Update the top-left corner
        if (mat.matTopLeft.x < this.matTopLeft.x) {
            this.matTopLeft.x = mat.matTopLeft.x;
        }
        if (mat.matTopLeft.y < this.matTopLeft.y) {
            this.matTopLeft.y = mat.matTopLeft.y;
        }

        // Update the bottom-right corner
        if (mat.matBottomRight.x > this.matBottomRight.x) {
            this.matBottomRight.x = mat.matBottomRight.x;
        }
        if (mat.matBottomRight.y > this.matBottomRight.y) {
            this.matBottomRight.y = mat.matBottomRight.y;
        }
    }

    void printBounds() {
        println("matTopLeft: " + this.matTopLeft);
        println("matBottomRight: " + this.matBottomRight);
    }

    void display(float scaleFactor) {
        for (toioMat mat : mats) {
            pushMatrix();
            translate(mat.position.x, mat.position.y);
            rotate(radians(mat.rotation));
            float matWidth = (mat.matBottomRight.x - mat.matTopLeft.x);
            float matHeight = (mat.matBottomRight.y - mat.matTopLeft.y);

            // Set fill color based on posture
            switch(mat.posture) {
                case 1: // Floor
                    fill(220); // Light green
                    break;
                case 2: // Ceiling
                    fill(200, 150, 150); // Light red
                    break;
                case 3: // Wall
                    fill(150, 150, 200); // Light blue
                    break;
            }

            rectMode(CENTER);
            stroke(0);
            rect(0, 0, matWidth * scaleFactor, matHeight * scaleFactor);

            // Draw the mat ID and posture type
            fill(0);
            textAlign(CENTER, CENTER);
            textSize(24 * scaleFactor);
            text(mat.id, 0, -10 * scaleFactor);
            popMatrix();
        }
    }
}

class toioMat {
    int id;
    PVector matTopLeft;
    PVector matBottomRight;
    PVector position; // Absolute position on the screen
    float rotation;   // Rotation in degrees
    int posture;      // 1: floor, 2: ceiling, 3: wall

    toioMat(int id, PVector position, float rotation, int posture) {
        this.id = id;
        this.position = position;
        this.rotation = rotation;
        this.posture = posture;

        switch (id) {
            case 0:  // toio core cube simple play mat
                this.matTopLeft = new PVector(98, 142);
                this.matBottomRight = new PVector(402, 358);
                break;
            case 1:
                this.matTopLeft = new PVector(34, 35);
                this.matBottomRight = new PVector(339, 250);
                break;
            case 2:
                this.matTopLeft = new PVector(34, 251);
                this.matBottomRight = new PVector(339, 466);
                break;
            case 3:
                this.matTopLeft = new PVector(34, 467);
                this.matBottomRight = new PVector(339, 682);
                break;
            case 4:
                this.matTopLeft = new PVector(34, 683);
                this.matBottomRight = new PVector(339, 898);
                break;
            case 5:
                this.matTopLeft = new PVector(340, 35);
                this.matBottomRight = new PVector(644, 250);
                break;
            case 6:
                this.matTopLeft = new PVector(340, 251);
                this.matBottomRight = new PVector(644, 466);
                break;
            case 7:
                this.matTopLeft = new PVector(340, 467);
                this.matBottomRight = new PVector(644, 682);
                break;
            case 8:
                this.matTopLeft = new PVector(340, 683);
                this.matBottomRight = new PVector(644, 898);
                break;
            case 9:
                this.matTopLeft = new PVector(645, 35);
                this.matBottomRight = new PVector(949, 250);
                break;
            case 10:
                this.matTopLeft = new PVector(645, 251);
                this.matBottomRight = new PVector(949, 466);
                break;
            case 11:
                this.matTopLeft = new PVector(645, 467);
                this.matBottomRight = new PVector(949, 682);
                break;
            case 12:
                this.matTopLeft = new PVector(645, 683);
                this.matBottomRight = new PVector(949, 898);
                break;
            case 13:  // toio collection play mat
                this.matTopLeft = new PVector(45, 45);
                this.matBottomRight = new PVector(455, 455);
                break;
            default:
                throw new IllegalArgumentException("Invalid mat ID");
        }
    }

    PVector convertToMatCoordinates(PVector screenPos, float scaleFactor) {
        float dx = screenPos.x - position.x;
        float dy = screenPos.y - position.y;
        float angle = radians(-rotation);
        float rotatedX = dx * cos(angle) - dy * sin(angle);
        float rotatedY = dx * sin(angle) + dy * cos(angle);
        float matX = rotatedX / scaleFactor + matTopLeft.x;
        float matY = rotatedY / scaleFactor + matTopLeft.y;
        return new PVector(matX, matY);
    }

    PVector convertToScreenCoordinates(PVector matPos, float scaleFactor) {
        float dx = (matPos.x - matTopLeft.x) * scaleFactor;
        float dy = (matPos.y - matTopLeft.y) * scaleFactor;
        float angle = radians(rotation);
        float rotatedX = dx * cos(angle) - dy * sin(angle);
        float rotatedY = dx * sin(angle) + dy * cos(angle);
        float screenX = rotatedX + position.x;
        float screenY = rotatedY + position.y;
        return new PVector(screenX, screenY);
    }

    boolean containsPoint(float x, float y) {
        return x >= matTopLeft.x && x <= matBottomRight.x &&
               y >= matTopLeft.y && y <= matBottomRight.y;
    }

    toioMat findMatForPoint(matList mats, float x, float y, int posture) {
        for (toioMat mat : mats.mats) {
            if (mat.id != 0 && mat.id != 13 && // Ignore mats 0 and 13
                mat.posture == posture &&
                mat.containsPoint(x, y)) {
                return mat;
            }
        }
        return null;
    }

    PVector matToDisplayCoords(float x, float y, float scaleFactor) {
        // Calculate mat dimensions
        float matWidth = matBottomRight.x - matTopLeft.x;
        float matHeight = matBottomRight.y - matTopLeft.y;

        // Calculate relative position from the mat's center
        float relX = (x - matTopLeft.x - matWidth/2) * scaleFactor;
        float relY = (y - matTopLeft.y - matHeight/2) * scaleFactor;

        // Apply mat rotation
        float angle = radians(rotation);
        float rotX = relX * cos(angle) - relY * sin(angle);
        float rotY = relX * sin(angle) + relY * cos(angle);

        // Translate to absolute position
        return new PVector(position.x + rotX, position.y + rotY);
    }
}
