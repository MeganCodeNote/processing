// Email:  meganleesf@gmail.com
// Date:   11/27/2014
// Description: This is a project for user to visualize 
//              an interactive parallel coordinates

import java.lang.Object;
import java.util.Arrays;
import java.util.HashSet;

/**
 * Global variables
 */
// settings of the canvas
int WIDTH = 1000;       // width of window size
int HEIGHT = 680;       // height of window size
int YMARGIN = 90;       // top/bottom margin
int XMARGIN = 90;       // left/right margin
int[] canvas = {XMARGIN, YMARGIN + 10, WIDTH - XMARGIN - 50, HEIGHT - YMARGIN + 10};  // x1, y1, x2, y2 of the splom area

// data related
Table table;            // all teh data
String filepath;        // record the file path selected by the user
String[] fields;        // the headers from the csv file
float[][] values;       // the values of the csv file content
float[] mins;           // the min value of each column
float[] maxs;           // the max value of each column
boolean finishedLoad = false;  // will be set true after the data are loaded

// axes related
int numTicks = 10;      // how many ticks will there be on the axes

// file chooser's button setting
int[] button = {WIDTH - 150, 20, WIDTH - 20, 50};  // x1, y1, weight, height of the file chosser button

// for the brushing function
int[] curBar = {0, 0, 0, 0};
int curBarIndex = -1;

// color related
int[] color1 = {0, 224, 224};    // water blue
int[] color2 = {255, 255, 80};   // yellow
HashSet<Integer> selectedIndex = new HashSet<Integer>();  // record the index of the selected rows

//---------------------- PART I: Draw the graph ----------------------//

void setup() {
  // set the size of the window
  size(WIDTH, HEIGHT);
  background(#FFFFFF);
  smooth();

  // first ask the user to up load a file, callback: "fileSelected"
  finishedLoad = false;
  selectInput("Select a file to process:", "fileSelected");
}

void draw() {
  // update background
  background(#FFFFFF);
  
  // draw file chooser for user to change file
  drawFileChooser();
  
  // draw the parallel coordinates
  try {
    if (finishedLoad) {
      mins = new float[fields.length];
      maxs = new float[fields.length];
      drawParaCoords();
      drawBrush();
    }

  } catch (Exception e) {}
}


/**
 * Draw the parallel coordinates in the area defined in variable int[] canvas
 */
void drawParaCoords() {
  // clear the index (which lines to draw) for coloring
  if (!hasBrush) {
    selectedIndex.clear();
  }
  
  // draw readme
  text("1. Brush a section of axis to view details", 100, 20);
  text("2. Processing is slow, please move the brush area slowly", 100, 35);
  text("3. Click any place other than the brush area to disable brush", 100, 50);
  
  // first get the min and max for each axes
  int numAxes = fields.length;
  int axesGap = (canvas[2] - canvas[0]) / (numAxes - 1);
  for (int i = 0; i < numAxes; i++) {
    // draw the axis line
    int x1 = canvas[0] + i * axesGap;
    int y1 = canvas[1];
    int x2 = canvas[0] + i * axesGap;
    int y2 = canvas[3];
    line(x1, y1, x2, y2);
    
    // store the min and max values
    float minVal = minArr(values[i]);
    mins[i] = minVal;
    float maxVal = maxArr(values[i]);
    maxs[i] = maxVal;
  } 
  
  // draw the value lines
  fill(255);
  strokeWeight(1);
  for (int k = 0; k < table.getRowCount(); k++) {
    TableRow row = table.getRow(k);
    float val0 = row.getFloat(fields[0]);
    int lastX = canvas[0];
    int lastY = int(map(val0, mins[0], maxs[0], canvas[3], canvas[1]));
    int r = int(map(lastY, canvas[3], canvas[1], color1[0], color2[0]));
    int g = int(map(lastY, canvas[3], canvas[1], color1[1], color2[1]));
    int b = int(map(lastY, canvas[3], canvas[1], color1[2], color2[2]));
    // for the first axis check if user need to enable brush
    if (hasBrush && curBarIndex == 0) {
      if (pointInRect(brushPos, lastX, lastY)) {
        selectedIndex.add(k);
      } else {
        selectedIndex.remove(k);
      }
    }
      
    for (int i = 1; i < fields.length; i++) {
      float val = row.getFloat(fields[i]);
      int curX = lastX + axesGap;
      int curY = int(map(val, mins[i], maxs[i], canvas[3], canvas[1]));
      if (!hasBrush) {
        stroke(r, g, b);
      } else {
        stroke(235);
      }
      line(lastX, lastY, curX, curY);
      lastX = curX;
      lastY = curY;
      
      // get the index of the brushed lines
      if (hasBrush && curBarIndex == i) {
        if (pointInRect(brushPos, curX, curY)) {
          selectedIndex.add(k);
        } else {
          selectedIndex.remove(k);
        }
      }
    }
  }
  
  // draw the second layer of the value line (colored by brush)
  if (hasBrush) {
    for (int k = 0; k < table.getRowCount(); k++) {
      if (!selectedIndex.contains(k)) {
        continue;
      }
      TableRow row = table.getRow(k);
      float val0 = row.getFloat(fields[0]);
      int lastX = canvas[0];
      int lastY = int(map(val0, mins[0], maxs[0], canvas[3], canvas[1]));
      int r = int(map(lastY, canvas[3], canvas[1], color1[0], color2[0]));
      int g = int(map(lastY, canvas[3], canvas[1], color1[1], color2[1]));
      int b = int(map(lastY, canvas[3], canvas[1], color1[2], color2[2]));
      for (int i = 1; i < fields.length; i++) {
        float val = row.getFloat(fields[i]);
        int curX = lastX + axesGap;
        int curY = int(map(val, mins[i], maxs[i], canvas[3], canvas[1]));
        stroke(r, g, b);
        line(lastX, lastY, curX, curY);
        lastX = curX;
        lastY = curY;
      }
    }
  }

  
  // draw the vertical axes and the label
  stroke(100);
  for (int i = 0; i < numAxes; i++) {
    // draw the axis line
    int x1 = canvas[0] + i * axesGap;
    int y1 = canvas[1];
    int x2 = canvas[0] + i * axesGap;
    int y2 = canvas[3];
    line(x1, y1, x2, y2);
    
    // draw the ticks label on the axis
    float minVal = mins[i];
    float maxVal = maxs[i];
    int tickGap = (y2 - y1) / numTicks;
    for (int k = 0; k < numTicks + 1; k++) {
      int yVal = y1 + (numTicks - k) * tickGap;
      float label = map(yVal, y2, y1, minVal, maxVal);
      line(x1, yVal, x1 + 5, yVal);
      drawText(String.format("%.1f", label), x1 + 3, yVal);
    }
    
    // draw the axis title
    text(fields[i], x1 - 20, y1 - 20);
    
    // make the cross mark visible
    if (!hasBrush) {
      int[] rect = {x1 - 15, y1, x2 + 25, y2};
      drawCrossMark(rect, i);
    }
  } 
}


/**
 * Draw the parallel coordinates in the area defined in variable int[] canvas
 */
void drawBrush() {
  if (hasBrush) {
    fill(60, 100);
    strokeWeight(2);
    stroke(255);
    drawRect(brushPos);
  }
}


/**
 * Draw a rect "myrect": x1, y1, x2, y2 (upperleft corner and bottom right corner)
 */
void drawRect(int[] myrect) {
  rect(myrect[0], myrect[1], max(0, myrect[2] - myrect[0]), max(0, myrect[3] - myrect[1]));
}

/**
 * Draw a text with white shadow
 */
void drawText(Object text, int x, int y) {
  textSize(14);
  fill(255);
  text(text.toString(), x, y);
  textSize(12);
  fill(100);
  text(text.toString(), x + 3, y);
}


/**
 * Draw the button for the file chooser
 */
void drawFileChooser() {
  // draw the file chooser's button
  strokeWeight(2);
  if (mouseInRect(button)) {
    stroke(255);
    fill(#330066, 100);
    rect(button[0], button[1], button[2] - button[0], button[3] - button[1]);
    fill(255);
    textSize(13);
    text("Open a CSV file", button[0] + 15, button[1] + 20);
  } else {
    stroke(200);
    fill(255);
    rect(button[0], button[1], button[2] - button[0], button[3] - button[1]);
    fill(100);
    textSize(12);
    text("Open a CSV file", button[0] + 15, button[1] + 20);
  }
  strokeWeight(1);
}


/**
 * int[] pos stores x1, y1, x2, y2: if mouse is in the range, a cross mark will show
 */
void drawCrossMark(int[] rect, int i) {
  if (mouseInRect(rect)) {
    int x = mouseX - 5;
    int y = mouseY - 5;
    line(x - 5, y, x + 5, y);
    line(x, y - 5, x, y + 5);
    curBar = rect; // set cur to rect for the bounds of the brush area
    curBarIndex = i;
  }
}

//---------------------- PART II: File related functions ----------------------//

/**
 * The callback function for file-chooser, return the chosen file path
 */
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    // read in the chosen file
    println("User selected " + selection.getAbsolutePath());
    filepath = selection.getAbsolutePath();  
    readCSVFile(filepath);
  }
}


/**
 * The fucntion to load a csv file
 */
void readCSVFile(String filename) {
  // Get the header line
  BufferedReader reader = createReader(filename);
  try {
    String header = reader.readLine();
    fields = header.split(",");
    println("There are(is) " + fields.length + " header(s): " + header);
  } catch (IOException e) {
    e.printStackTrace();
  }
  
  // Store the headers into variable fields and load the content
  // expect all fields are float/int numbers
  table = loadTable(filename, "header");
  values = new float[fields.length][table.getRowCount()];
  for (int i = 0; i < fields.length; i++) {
    for (int j = 0; j < table.getRowCount(); j++) {
      Float num = table.getRow(j).getFloat(fields[i]);
      values[i][j] = num;
      println(num);
    }
  }
  finishedLoad = true;
}


//---------------------- PART III: Utility functions ----------------------//

/**
 * int[] pos stores x1, y1, x2, y2: return if mouse is in the range
 */
boolean mouseInRect(int[] rect) {
  return rect[0] < mouseX && mouseX < rect[2] && rect[1] < mouseY && mouseY < rect[3];
}

boolean pointInRect(int[] rect, int x, int y) {
  return rect[0] <= x && x <= rect[2] && rect[1] <= y && y <= rect[3];
}


/**
 * Get the max value in a float integer array
 */
float maxArr(float[] arr) {
  if (arr == null || arr.length == 0) {
    return Float.MIN_VALUE;
  }
  
  float[] copy = Arrays.copyOf(arr, arr.length);
  Arrays.sort(copy);
  return copy[arr.length - 1];
}

/**
 * Get the min value in a float integer array
 */
float minArr(float[] arr) {
  if (arr == null || arr.length == 0) {
    return Float.MAX_VALUE;
  }
 
  float[] copy = Arrays.copyOf(arr, arr.length);
  Arrays.sort(copy);
  return copy[0];
}



//---------------------- PART IV: Mouse Events for interactivity ----------------------//
int i = 0;
/**
 * Mouse event for the file chooser button
 */
void mouseClicked() {
  if (mouseInRect(button)) {
      finishedLoad = false;
      selectInput("Select a file to process:", "fileSelected");
  }
}

boolean hasBrush;
boolean drawBrush;
int[] brushPos = new int[4];
int[] moveStart = new int[2];


/**
 * For drawing the brush rectangle and move the brush area
 */
void mousePressed() {
  // no brush area, start drawing brush rect
  if (!hasBrush) {
    if (mouseInRect(curBar)) {
      brushPos[0] = curBar[0];
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
      brushPos[2] = curBar[2] - 10;
      brushPos[3] = min(mouseY, curBar[3] - 2);
    
    // in the process of moving the brush area
    } else {
      int[] trackArea = {brushPos[0], canvas[1], brushPos[2], canvas[3]};
      if (pointInRect(trackArea, mouseX, mouseY)) { // set the bounds, could not move beyond this
        int dx = mouseX - moveStart[0];
        int dy = mouseY - moveStart[1];
        moveStart[0] = mouseX;
        moveStart[1] = mouseY;
        
        // make sure the brush area won't go off curSubarea
        int x1 = brushPos[0] + dx;
        int y1 = brushPos[1] + dy;
        int x2 = brushPos[2] + dx;
        int y2 = brushPos[3] + dy;
        if (pointInRect(trackArea, x1, y1) && pointInRect(trackArea, x2, y2)) {
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


