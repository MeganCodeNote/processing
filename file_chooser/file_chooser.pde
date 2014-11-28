// Author: Megan Lee
// Email:  meganleesf@gmail.com
// Date:   11/20/2014
// Description: This is a project for user to visualize basic graphs
//              1. User select a csv file
//              2. If there is only 1 column, a BAR graph will show
//              3. If there are 2 columns, the script will draw a SCATTER PLOT
//              4. If there are more than 3 columns, you will see a SCATTER PLOT MATRIX
//              5. A SLIDER is provided for user to dynamically FILTER data
//              6. Highlight with color change and tooltip around mouse position enabled

import java.util.Collections;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.HashMap;


//------------------- PART I: Setting up / Initialization  ---------------//

/**
 * Global variables
 */
String filepath;       // record the file path selected by the user
String[] fields = {};  // the headers from the csv file
float[][] values;      // the values of the csv file content
int WIDTH = 900;       // width of window size
int HEIGHT = 650;      // height of window size
int PADDING = 100;      // top, bottom, left, right padding
int SLIDER = 30;       // height of the slider area height
HScrollbar slider;     // slider
HScrollbar slider2;    // slider
Float sliderWidth;     // slider's width
int[] button = {WIDTH - 150, 20, WIDTH - 20, 50};  // x1, y1, weight, height of the file chosser button

// for bar chart
int TICKWIDTH = 10;    // the length of the ticks on y-axis

// for splom chart

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


/**
 * Initialization function, setting up for processing program
 */
void setup() {
  // set the size of the window
  size(WIDTH, HEIGHT + SLIDER);
  background(#FFFFFF);
  smooth();

  // first ask the user to up load a file, callback: "fileSelected"
  selectInput("Select a file to process:", "fileSelected");
  
  // define the slider
  sliderWidth = float(width - 4 * PADDING);
  slider = new HScrollbar(2 * PADDING, height - SLIDER * 2.5, int(sliderWidth), 20, 20);
  slider2 = new HScrollbar(2 * PADDING, height - SLIDER * 1.5, int(sliderWidth), 20, 20);
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
  if (fields.length > 2) {
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


/**
 * Mouse event for the file chooser button
 */
void mouseClicked() {
  if (mouseInRect(button)) {
      selectInput("Select a file to process:", "fileSelected");
  }
}

//------------------------  PART II: For Drawing Graphs -------------------------//

/**
 * The function for processing to actually draw the graphs
 */
void draw() {
  // update background and show slider, file chooser button
  background(#FFFFFF);
  
  // draw the file chooser button
  drawFileChooser();
  
  // 1 column, draw a bar graph
  if (fields.length == 1 && values != null) {
    slider.update();
    slider.display();
    
    drawBar();
    
  // 2 columns, draw a scatter plot
  } else if (fields.length == 2){
    slider.update();  // slider to filter value on x-axis
    slider.display();
    slider2.update(); // slider to filter value on y-axis
    slider2.display();
    
    drawScatterplot();
    
  // >= 3 columns, draw a scatter plot matrix
  } else if (fields.length > 2) {
    try {
      drawSplom(); 
    } catch (Exception e) {}
  }
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
 * Draw axis (x/y coordinate and title), called by drawBar() drawScatterplot() and drawSplom()
 */
void drawAxes(int graphID) {
  // draw the title of the bar graph
  textSize(20);
  if (graphID == 1) { // graphID mean the number of columns in CSV file
    text("Bar Graph of " + fields[0], width / 2 - 100, PADDING / 2);    
  } else if (graphID == 2) {
    text("Scatterplot of " + fields[0] + ", " + fields[1], width / 2 - 100, PADDING / 2);
  }
  textSize(12);
  
  // draw the axis
  stroke(#888888);
  strokeWeight(1);
  fill(#888888);

  // draw the x-axis
  int x1 = PADDING;
  int x2 = width - PADDING;
  int y1 = HEIGHT - PADDING;
  int y2 = y1;
  line(x1, y1, x2, y2);

  // draw the tick on x-axis (for scatterplot)
  if (graphID == 2) {
      int tickGap = (width - PADDING * 2) / 5;
      for (int j = 0; j < 5; j++) {
        line(x1 + (j + 1) * tickGap, y1, x1 + (j + 1) * tickGap, y1 + TICKWIDTH);
      }
  }
  
  // draw the y-axis
  x1 = PADDING;
  x2 = x1;
  y1 = HEIGHT - PADDING;
  y2 = PADDING;
  line(x1, y1, x2, y2);
  
  // draw the ticks on y-axis
  int tickGap = (y1 - y2) / 5;
  for (int j = 0; j < 5; j++) {
    if (graphID == 1) {
      line(x1, y2 + j * tickGap, x1 + TICKWIDTH, y2 + j * tickGap);
    } else if (graphID == 2) {
      line(x1, y2 + j * tickGap, x1 - TICKWIDTH, y2 + j * tickGap);
    }
  }
}


/**
 * The function for drawing a bar chart
 */
void drawBar() {  
  // get the max bar values for slider range
  float[] allBars;            // all values from input file
  ArrayList<Float> bars;      // the selected group of bars filtered by the slider
  int N;                      // number of bars selected
  float maxVal;               // the max value
  try {
    allBars = values[0];
    N = allBars.length;
    maxVal = sort(allBars)[N - 1];
  } catch (Exception e) {
    return;
  }
  
  // show the value on the slider
  int sliderBarVal = int(maxVal * (slider.getPos() - 2 * PADDING) / sliderWidth);
  int sliderValRange = sliderBarVal - sliderBarVal % 5;
  text("Show bars with values <= " + sliderValRange, slider.getPos() - PADDING * 3 / 2, height - PADDING);
    
  // draw the x/y coordinates
  drawAxes(1);
    
  // get the selected bars (values no larger than the slected value through silder)
  try {
    // selet filterd bars
    bars = new ArrayList<Float>();
    for (Float num : allBars) {
      if (num <= sliderValRange) {
        bars.add(num);
      }
    } 
    N = bars.size();
    
    // get the max value to show on y-axis
    ArrayList<Float> barsCopy = new ArrayList<Float>(bars);
    Collections.sort(barsCopy);
    maxVal = barsCopy.get(N - 1);
  } catch (Exception e) {
    return;
  }
  
  // draw the bars
  if (bars == null || N == 0) {
    return;
  }
  int maxBarHeight = HEIGHT - 2 * PADDING;    // top/bottem 1 padding;
  int barWidth = (width - 4 * PADDING) / N;   // right/left 2 paddings;
  for (int i = 0; i < N; i++) {
    // compute bar property
    int barHeight = int(bars.get(i) / maxVal * maxBarHeight);
    int barX = 2 * PADDING + (barWidth * i);
    int barY = HEIGHT - barHeight - PADDING;

    // draw the bars
    noStroke();
    fill(#FF3B7B);
    rect(barX, barY, barWidth * 0.7, barHeight);
    
    // mouse over effects with color change and tooltip
    if (barX < mouseX && mouseX < barX + barWidth * 0.7 
        && barY < mouseY && mouseY < HEIGHT - PADDING) {
           fill(#B5E8CC);
           noStroke();
           rect(barX, barY, barWidth * 0.7, barHeight);
           fill(#495151);
           text(String.format("%d", int(bars.get(i))), mouseX - barWidth * 0.3, mouseY - 10);
    }
    
    // draw the number on y-axis
    stroke(#888888);
    strokeWeight(1);
    fill(#888888);
    for (int j = 0; j < 5; j++) {
      text(String.format("%.1f", maxVal * (5 - j) / 5), PADDING + 10, PADDING + (HEIGHT - 2 * PADDING) * j / 5);
    }
  }
}


/**
 * The function for drawing a scatter plot
 */
void drawScatterplot() {
  // get the max values for 2 metrics
  float maxX;
  float[] xArr;
  float maxY;
  float[] yArr;
  try {
    xArr = values[0];  // the first column
    yArr = values[1];  // the second column
    maxX = Float.MIN_VALUE;
    maxY = Float.MIN_VALUE;
    for (int i = 0; i < xArr.length; i++) {
      if (maxX < xArr[i]) {
        maxX = xArr[i];
      }
      if (maxY < yArr[i]) {
        maxY = yArr[i];
      }
    }
  } catch (Exception e) {
    return;
  }

  // first show the value on the slider
  int xSliderBarVal = int(maxX * (slider.getPos() - 2 * PADDING) / sliderWidth);
  int xSliderValRange = xSliderBarVal - xSliderBarVal % 5;
  text("Show points with " + fields[0] + " <= " + xSliderBarVal, slider.getPos() - PADDING * 3 / 2, height - PADDING + 10);
  
  int ySliderBarVal = int(maxY * (slider2.getPos() - 2 * PADDING) / sliderWidth);
  int ySliderValRange = ySliderBarVal - ySliderBarVal % 5;
  text("Show points with " + fields[1] + " <= " + ySliderBarVal, slider2.getPos() - PADDING * 3 / 2, height - PADDING / 4);

  // draw the x/y coordinates
  drawAxes(2);
  
  // draw labels on the axes
  int tickGap = (width - PADDING * 2) / 5;
  for (int j = 0; j <= 5; j++) {
    text(int(xSliderBarVal * j / 5.0), PADDING + j * tickGap + 2, HEIGHT - PADDING + TICKWIDTH + 5);
  }
  
  // draw labels on the axes
  tickGap = (HEIGHT - PADDING * 2) / 5;
  for (int j = 5; j > 0; j--) {
    text(int(ySliderBarVal * j / 5.0), PADDING - 35, PADDING + (5 - j) * tickGap - 2);
  }
  
  // get the selected points
  int count = 0;
  ArrayList<PVector> selectedPoints = new ArrayList<PVector>();
  for (int i = 0; i < xArr.length; i++) {
    if (xArr[i] <= xSliderBarVal && yArr[i] <= ySliderBarVal) {
      count++;
      selectedPoints.add(new PVector(xArr[i], yArr[i]));
    }
  }
  
  // show the points in the coordinates
  for (PVector point : selectedPoints) {
    // draw the x-axis
    int x1 = PADDING;
    int x2 = width - PADDING;
    int xPos = int(map(point.x, 0, xSliderBarVal, x1, x2));
    int y1 = HEIGHT - PADDING;
    int y2 = PADDING;
    int yPos = int(map(point.y, 0, ySliderBarVal, y1, y2));  
    noStroke();
    fill(#99FF33); 
    ellipse(xPos, yPos, 10, 10);
      
    // add the tooltip for hover over effect
    if (sq(mouseX - xPos) + sq(mouseY - yPos) < 200) {
      fill(#009999); 
      ellipse(xPos, yPos, 20, 20);
      fill(#222222);
      text(point.x + ", " + point.y, mouseX + 15, mouseY);
    }
  }

    
}


/**
 * The fucntion for drawing a scatter plot matrix
 */
void drawSplom() {
  // draw the title alert user to use the brush function
  fill(#606060);
  textSize(20);
  text("BRUSH over areas for details", 250, 25);
  textSize(12);
  
  // draw the splom background gridlines
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
        println(s + " " + i);

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



//------------------------  PART IV: Splom Utils -------------------------//

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


/**
 * For drawing the brush rectangle and move the brush area
 */
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


/**
 * For drawing the brush rectangle and move the brush area
 */
void mouseReleased() {
  // stop draw brush area when the mouse is released
  if (drawBrush) {
    drawBrush = false;
  }
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


/**
 * Given any integer i, will return a 8 color scheme
 */
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

//------------------------  PART V: Slider Utils -------------------------//
/**
 * The class for the slider 
 * (reference: https://processing.org/examples/scrollbar.html)
 */
class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;

  HScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);
  }

  float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
}
