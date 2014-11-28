// This sketch is related to scatterplom matrix's brush function
//
// 1) a cross will shown in the graph canvas area
// 2) in the graph canvas area, we can draw a brush area
// 3) when there is a brush area, if we click outside the brush area, the brush area will disappear
// 4) when there is a brush area, if we drag mouse inside the brush area, the brush area will move
// 5) if we draw/move the brush area, the square won't move outside the graph canvas area

boolean hasBrush = false;      // indicating whether there is a brush area on canvas
boolean drawBrush = false;     // we are current drawing the brush area
int[] brushPos = new int[4];   // x1, y1, x2, y2 for the brush area
int[] moveStart = new int[2];  // the position of the mouse when we start moving the brush rect
int[] canvas = {70, 50, 570, 250}; // the positions of the graph canvas area

void setup() {
  background(#FFFFFF);
  size(640, 320);
}

void draw() {
  background(#FFFFFF);
  
  // graph canvas area
  fill(255);
  stroke(120);
  strokeWeight(1);
  rect(70, 50, 500, 200);

  if (hasBrush) {  
    // draw the brush rect
    int brushWidth = max(0, brushPos[2] - brushPos[0]);
    int brushHeight = max(0, brushPos[3] - brushPos[1]);
    fill(100, 20);
    strokeWeight(2);
    stroke(255);
    rect(brushPos[0], brushPos[1], brushWidth, brushHeight);
    
  } else {
    showCrossMark(canvas);
  }
}


/**
 * int[] pos stores x1, y1, x2, y2: if mouse is in the range, a cross mark will show
 */
void showCrossMark(int[] pos) {
  if (mouseInRect(pos)) {
    int x = mouseX - 5;
    int y = mouseY - 5;
    line(x - 5, y, x + 5, y);
    line(x, y - 5, x, y + 5);
  }
}


/**
 * int[] pos stores x1, y1, x2, y2: return if mouse is in the range
 */
boolean mouseInRect(int[] rect) {
  return rect[0] < mouseX && mouseX < rect[2] && rect[1] < mouseY && mouseY < rect[3];
}

boolean pointInRect(int[] rect, int x, int y) {
  return rect[0] < x && x < rect[2] && rect[1] < y && y < rect[3];
}

/**
 * For drawing the brush rectangle and move the brush area
 */
void mousePressed() {
  // no brush area, start drawing brush rect
  if (!hasBrush) {
    if (mouseInRect(canvas)) {
      brushPos[0] = mouseX;
      brushPos[1] = mouseY;
      hasBrush = true;
      drawBrush = true;
    }
    
  // has brush area, mouse not in brush area, clear brush rect
  } else if (!mouseInRect(brushPos)) {
    for (int i = 0; i < 4; i++) {
      brushPos[i] = 0;
    }
    hasBrush = false;
  
  // has brush area, mouse in it, start moving the rect
  } else {
    moveStart[0] = mouseX;
    moveStart[1] = mouseY;
  }
}

void mouseDragged() {
  if (hasBrush) {
    // during the drawing of the rect
    if (drawBrush) {
      brushPos[2] = min(mouseX, canvas[2] - 2);
      brushPos[3] = min(mouseY, canvas[3] - 2);
    
    // in the process of moving the brush area
    } else {
      if (pointInRect(canvas, mouseX, mouseY)) {
        int dx = mouseX - moveStart[0];
        int dy = mouseY - moveStart[1];
        moveStart[0] = mouseX;
        moveStart[1] = mouseY;
        
        // make sure the brush area won't go off canvas
        int x1 = brushPos[0] + dx;
        int y1 = brushPos[1] + dy;
        int x2 = brushPos[2] + dx;
        int y2 = brushPos[3] + dy;
        if (pointInRect(canvas, x1, y1) && pointInRect(canvas, x2, y2)) {
          for (int i = 0; i <= 2; i += 2) {
            brushPos[i] += dx;
            brushPos[i + 1] += dy;
          }
        } 
      }
    }
  }
}


void mouseReleased() {
  // stop draw brush area when the mouse is released
  if (drawBrush) {
    drawBrush = false;
  }
}

