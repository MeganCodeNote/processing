// AUTHOR: megan lee meganleesf@gmail.com
// 
// NOET: assume that the csv file only contains fields of float/int type
//       for the splom file, assume that only the lass filed(colomn) contains string (for color, classification)
//
// STEPs for developing this Splom Brushing
// step 1: brush function implemented
// step 2: draw the grid lines and subareas
// step 3: activate brush function in each subarea
// step 4: draw points in each subarea
// step 5: color enables
// step 6: add the axis labels and color legend


import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.HashMap;

int WIDTH = 900;       // width of window size
int HEIGHT = 650;      // height of window size
int PADDING = 100;      // top, bottom, left, right padding
int SLIDER = 30;       // height of the slider area height
Float sliderWidth;     // slider's width
String[] fields = {};  // the headers from the csv file
float[][] values = {}; // the values of the csv file content

String filepath = "";          // the path of the data
boolean hasBrush = false;      // indicating whether there is a brush area on canvas
boolean drawBrush = false;     // we are current drawing the brush area
int[] brushPos = new int[4];   // x1, y1, x2, y2 for the brush area
int[] moveStart = new int[2];  // the position of the mouse when we start moving the brush rect
int[] curSubarea = new int[4]; // the current subareas in which the mouse is
String[] classifier = {};      // used for classify/color dots, last column in the csv file 
int YMARGIN = 50;      // for adjust the splom canvas
int XMARGIN = (WIDTH - HEIGHT - SLIDER) / 2 + YMARGIN;  // for adjust the splom canvas
int numCols = 0;       // the number of columns in the CSV file
int numSecs = 6;       // the number of sections for each axis label
int[] splom = {XMARGIN / 2, YMARGIN, WIDTH - XMARGIN, HEIGHT + SLIDER - YMARGIN};  // x1, y1, x2, y2 of the splom area
HashSet<Integer> selectedPointsIndex = new HashSet<Integer>();
HashMap<String, Integer> colorSet = new HashMap<String, Integer>();

void setup() {
  background(#FFFFFF);
  size(900, 680);
  smooth();
  
  // first ask the user to up load a file, callback: "fileSelected"
  selectInput("Select a file to process:", "fileSelected");
}

void draw() {
  try {
    drawSplom();
  } catch (Exception e) {} // there might be exception with the file chooser call back
}


void drawSplom() {
  // draw the splom background gridlines
  background(#FFFFFF);
  int xGridGap = (splom[3] - splom[1]) / (numCols * numSecs - 1);
  splom[3] = xGridGap * (numCols * numSecs - 1) + splom[1];
  int yGridGap = (splom[2] - splom[0]) / (numCols * numSecs - 1);
  splom[2] = yGridGap * (numCols * numSecs - 1) + splom[0];
  strokeWeight(1);
  stroke(230);
  for (int i = 0; i < numCols * numSecs; i++) {
    line(splom[0], splom[1] + i * xGridGap, splom[2], splom[1] + i * xGridGap);
    line(splom[0] + i * yGridGap, splom[1], splom[0] + i * yGridGap, splom[3]);
  }
   
  // get the corner points for the subareas and draw the subareas
  int[][] subareas = new int[numCols * numCols][4];
  for (int i = 0; i < numCols; i++) {
    for (int j = 0; j < numCols; j++) {
      int[] corners = new int[4];
      corners[0] = splom[0] + j * yGridGap * numSecs;
      corners[1] = splom[1] + i * xGridGap * numSecs;
      corners[2] = corners[0] + yGridGap * (numSecs - 1);
      corners[3] = corners[1] + xGridGap * (numSecs - 1);
      subareas[i * numCols + j] = corners;
      stroke(160);
      fill(255, 80);
      rect(corners[0], corners[1], yGridGap * (numSecs - 1), xGridGap * (numSecs - 1));  
    }
  }
  
  // draw pionts in each of the subareas
  for (int i = 0; i < numCols; i++) {
    for (int j = 0; j < numCols; j++) {
      /** NOTE: The ith column and jth column's scatterplot will be shown
       *  at row: i, and col: (numCols - j - 1)
       */
       
       // first get the associate subarea
       int[] area = subareas[i * numCols + (numCols - j - 1)];
       
       // then get the data, select the right color and draw points
       float[] yVals = values[i];
       float maxY = maxArr(yVals), minY = minArr(yVals);
       float[] xVals = values[j];
       float maxX = maxArr(xVals), minX = minArr(xVals);
       int x1 = area[0], x2 = area[2];
       int y1 = area[1], y2 = area[3];
       for (int k = 0; k < yVals.length; k++) {
         int xPos = int(map(xVals[k], minX, maxX, x1, x2));
         int yPos = int(map(yVals[k], minY, maxY, y2, y1));
         
         // set default color
         int colorIndex = colorSet.get(classifier[k]);
         colorPicker(colorIndex);

         // use a selectedPointsIndex to record the selected brushed points
         if (hasBrush && pointInRect(curSubarea, xPos, yPos)) {
           if (pointInRect(brushPos, xPos, yPos)) {
             selectedPointsIndex.remove(k);
           } else {
             selectedPointsIndex.add(k);
           }
         } 
         
         if (!hasBrush) {
            selectedPointsIndex.clear();
         }
         
         // set the colors and draw the points
         if (selectedPointsIndex.contains(k)) {
           fill(220);
         } else {
            colorPicker(colorIndex);
         }
         noStroke();
         ellipse(xPos, yPos, 6, 6);
       } 
       
       // draw the x-axis number labels
       fill(180);
       if (i == numCols - 1) {
         for (int k = 0; k < numSecs; k++) {
           float label = map(area[0] + k * yGridGap, area[0], area[2], minX, maxX);
           text(String.format("%.1f",label), area[0] + k * yGridGap - 6, area[3] + 15);
         }
       }
       
       // draw the y-axis number labels
       if (j == numCols - 1) {
         for (int k = 0; k < numSecs; k++) {
           float label = map(area[1] + k * xGridGap, area[1], area[3], minY, maxY);
           text(String.format("%.1f",label), area[0] - 25, area[1] + (numSecs - 1 - k) * xGridGap + 6);
         }
       }
    } // end of for loop j
  } // end of for loop i

  // draw the colored legend
  int[] legend = {WIDTH - 150, 200, 20, 20};
  for (String s : colorSet.keySet()) {
    int i = colorSet.get(s);
    colorPicker(i);
    rect(legend[0], legend[1] + 40 * i, legend[2], legend[3]);
    text(s, legend[0] + 30, legend[1] + 40 * i + 10);
  }
    
  // draw the brush area or the corss mark
  if (hasBrush) {  
    // draw the brush rect
    int brushWidth = max(0, brushPos[2] - brushPos[0]);
    int brushHeight = max(0, brushPos[3] - brushPos[1]);
    fill(100, 20);
    strokeWeight(2);
    stroke(255);
    rect(brushPos[0], brushPos[1], brushWidth, brushHeight);
    
  } else {
    // if we don't have brush area yet, show cross mark in each subarea
    for (int i = 0; i < numCols * numCols; i++) {
      stroke(0);
      showCrossMark(subareas[i]);
    }
  }
  
  // draw the fileds lable
  for (int i = 0; i < numCols; i++) {
    int[] subarea = subareas[i * numCols + numCols - 1 - i];
    fill(100);
    text(fields[i], subarea[0] + 5, subarea[1] + 15);
  }
}


/**
 * int[] pos stores x1, y1, x2, y2: if mouse is in the range, a cross mark will show
 */
void showCrossMark(int[] rect) {
  if (mouseInRect(rect)) {
    int x = mouseX - 5;
    int y = mouseY - 5;
    line(x - 5, y, x + 5, y);
    line(x, y - 5, x, y + 5);
    curSubarea = rect; // set curSubarea to rect for the bounds of the brush area
  }
}


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
 * For drawing the brush rectangle and move the brush area
 */
void mousePressed() {
  // no brush area, start drawing brush rect
  if (!hasBrush) {
    if (mouseInRect(curSubarea)) {
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
      brushPos[2] = min(mouseX, curSubarea[2] - 2);
      brushPos[3] = min(mouseY, curSubarea[3] - 2);
    
    // in the process of moving the brush area
    } else {
      if (pointInRect(curSubarea, mouseX, mouseY)) { // set the bounds, could not move beyond this
        int dx = mouseX - moveStart[0];
        int dy = mouseY - moveStart[1];
        moveStart[0] = mouseX;
        moveStart[1] = mouseY;
        
        // make sure the brush area won't go off curSubarea
        int x1 = brushPos[0] + dx;
        int y1 = brushPos[1] + dy;
        int x2 = brushPos[2] + dx;
        int y2 = brushPos[3] + dy;
        if (pointInRect(curSubarea, x1, y1) && pointInRect(curSubarea, x2, y2)) {
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
  Table table = loadTable(filename, "header");
  values = new float[fields.length][table.getRowCount()];
  for (int i = 0; i < fields.length; i++) {
    for (int j = 0; j < table.getRowCount(); j++) {
      Float num = table.getRow(j).getFloat(fields[i]);
      values[i][j] = num;
      println(num);
    }
  }
  
  // if it's a splom graph, store the last column int classifier (string value)
  if (fields.length >= 2) {
    classifier = new String[table.getRowCount()];
    for (int j = 0; j < table.getRowCount(); j++) {
      classifier[j] = table.getRow(j).getString(fields[fields.length - 1]);
      println(classifier[j]);
    }
    numCols = fields.length - 1;
    colorSetter();  // set the color using the last column in csv file
                    // colorSetter must be used after readCSVFile()
  }
}


float maxArr(float[] arr) {
  if (arr == null || arr.length == 0) {
    return Float.MIN_VALUE;
  }
 
  float[] copy = Arrays.copyOf(arr, arr.length);
  Arrays.sort(copy);
  return copy[arr.length - 1];
}

float minArr(float[] arr) {
  if (arr == null || arr.length == 0) {
    return Float.MAX_VALUE;
  }
 
  float[] copy = Arrays.copyOf(arr, arr.length);
  Arrays.sort(copy);
  return copy[0];
}

/**
 * Use the last column as the color indicator
 */
void colorSetter() {
  int count = 0;
  for (String s : classifier) {
    if (!colorSet.containsKey(s)) {
      colorSet.put(s, count++);
    }
  }
}

void colorPicker(int i) {
  i = i % 7;
  switch (i) {
    case 0:
      fill(#B266FF);
      break;
    case 1:
      fill(#FF66B2);
      break;
    case 2:
      fill(#66FFB2);
      break;
    case 3:
      fill(#FFFF66);
      break;
    case 4:
      fill(#66B2FF);
      break;
    case 5:
      fill(#FFB266);
      break;   
    case 6:
      fill(123, 244, 190);
      break;
  }
}
