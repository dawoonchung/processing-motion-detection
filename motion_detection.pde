/**
 * Motion detection with blobs.
 *
 * Based on this example by Jordi Tost:
 * https://github.com/jorditost/ImageFiltering/tree/master/ImageFilteringWithBlobPersistence
 *
 * @author Da-Woon Chung <dorapen@gmail.com>
 * @url https://github.com/dawoonchung 
 */

import processing.video.*;
import gab.opencv.*;
import controlP5.*;
import java.awt.Rectangle;

Capture video;
OpenCV opencv;

// Frame size
int frameWidth = 960 / 2;
int frameHeight = 720 / 2;

// Image variables
PImage src;
PImage adjustedImage;
PImage processedImage;
PImage contoursImage;

// Contour variables
ArrayList<Contour> contours;
ArrayList<Contour> newBlobContours; // List of detected contours parsed as blobs (every frame)

// Blob variables
ArrayList<Blob> blobList; // List of my blob objects (persistent)
int blobCount = 0; // Number of detected blobs over all time. Used to set IDs

// Initial configurations
float contrast = 1.35;
int brightness = 0;
int threshold = 75;
int blobSizeThreshold = 40;
int blurSize = 10;

// Control variables
ControlP5 cp5;
int buttonColor;
int buttonBgColor;

/**
 * Setup Control P5
 */
void initControls() {
  // Slider for contrast
  cp5.addSlider("contrast")
    .setLabel("Contrast")
    .setPosition(20, 50)
    .setRange(0.0, 6.0);

  // Slider for threshold
  cp5.addSlider("threshold")
    .setLabel("Threshold")
    .setPosition(20, 110)
    .setRange(0, 255);

  // Slider for blur size
  cp5.addSlider("blurSize")
    .setLabel("Blur size")
    .setPosition(20, 170)
    .setRange(1, 20);

  // Slider for minimum blob size
  cp5.addSlider("blobSizeThreshold")
    .setLabel("Minimum blob size")
    .setPosition(20, 230)
    .setRange(0, 100);

  // Store the default background color, we will need it later
  buttonColor = cp5.getController("contrast").getColor().getForeground();
  buttonBgColor = cp5.getController("contrast").getColor().getBackground();
}


/**
 * Contour analysis
 */
ArrayList<Contour> getBlobsFromContours(ArrayList<Contour> newContours) {  
  ArrayList<Contour> newBlobs = new ArrayList<Contour>();

  // Which of these contours are blobs?
  for (int i = 0; i < newContours.size(); i += 1) {
    Contour contour = newContours.get(i);
    Rectangle r = contour.getBoundingBox();

    if (r.width < blobSizeThreshold || r.height < blobSizeThreshold) {
      continue;
    }

    newBlobs.add(contour);
  }

  return newBlobs;
}

/**
 * Blob detection
 */
void detectBlobs() {
  // Contours detected in this frame
  // Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true, true);
  newBlobContours = getBlobsFromContours(contours);
  // println(contours.length);

  // Check if the detected blobs already exist are new or some has disappeared. 

  // SCENARIO 1 
  // blobList is empty
  if (blobList.isEmpty()) {
    // Just make a Blob object for every face Rectangle
    for (int i = 0; i < newBlobContours.size(); i += 1) {
      println("+++ New blob detected with ID: " + blobCount);
      blobList.add(new Blob(this, blobCount, newBlobContours.get(i)));
      blobCount += 1;
    }

    // SCENARIO 2 
    // We have fewer Blob objects than face Rectangles found from OpenCV in this frame
  } else if (blobList.size() <= newBlobContours.size()) {
    boolean[] used = new boolean[newBlobContours.size()];
    // Match existing Blob objects with a Rectangle
    for (Blob b : blobList) {
      // Find the new blob newBlobContours.get(index) that is closest to blob b
      // set used[index] to true so that it can't be used twice
      float record = 50000;
      int index = -1;

      for (int i = 0; i < newBlobContours.size(); i += 1) {
        float d = dist(newBlobContours.get(i).getBoundingBox().x, newBlobContours.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);

        if (d < record && !used[i]) {
          record = d;
          index = i;
        }
      }
      // Update Blob object location
      used[index] = true;
      b.update(newBlobContours.get(index));
    }

    // Add any unused blobs
    for (int i = 0; i < newBlobContours.size(); i += 1) {
      if (!used[i]) {
        println("+++ New blob detected with ID: " + blobCount);
        blobList.add(new Blob(this, blobCount, newBlobContours.get(i)));
        blobCount += 1;
      }
    }

    // SCENARIO 3 
    // We have more Blob objects than blob Rectangles found from OpenCV in this frame
  } else {
    // All Blob objects start out as available
    for (Blob b : blobList) {
      b.available = true;
    } 
    // Match Rectangle with a Blob object
    for (int i = 0; i < newBlobContours.size(); i += 1) {
      // Find blob object closest to the newBlobContours.get(i) Contour
      // set available to false
      float record = 50000;
      int index = -1;
      for (int j = 0; j < blobList.size(); j += 1) {
        Blob b = blobList.get(j);
        float d = dist(newBlobContours.get(i).getBoundingBox().x, newBlobContours.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);

        if (d < record && b.available) {
          record = d;
          index = j;
        }
      }
      // Update Blob object location
      Blob b = blobList.get(index);
      b.available = false;
      b.update(newBlobContours.get(i));
    } 
    // Start to kill any left over Blob objects
    for (Blob b : blobList) {
      if (b.available) {
        b.countDown();

        if (b.dead()) {
          b.delete = true;
        }
      }
    }
  }

  // Delete any blob that should be deleted
  for (int i = blobList.size() - 1; i >= 0; i -= 1) {
    Blob b = blobList.get(i);
    if (b.delete) {
      blobList.remove(i);
    }
  }
}

/**
 * Display frames
 */
void displayImages() {  
  pushMatrix();
  scale(2);
  translate(-src.width / 2, 0);
  image(src, 0, 0);
  // image(adjustedImage, src.width, 0);
  // image(processedImage, 0, src.height);
  // image(processedImage, src.width, src.height);
  // noStroke();
  // fill(0);
  // rect(src.width, src.height, src.width, src.height);
  popMatrix();

  //stroke(255);
  //fill(255);
  //textSize(12);
  //text("Source", 10, 25); 
  //text("Adjusted", src.width / 2 + 10, 25); 
  //text("Processed (Motion tracking)", 10, src.height / 2 + 25); 
  //text("Active points", src.width / 2 + 10, src.height / 2 + 25);
}

/**
 * Display blob rectangles
 */
void displayBlobs() {
  for (Blob b : blobList) {
    strokeWeight(1);
    b.display();
  }
}

/**
 * Display detected contours
 */
void displayContours() { 
  // Contours
  for (int i = 0; i < contours.size(); i += 1) {
    Contour contour = contours.get(i);

    noFill();
    stroke(0, 255, 0);
    strokeWeight(3);
    contour.draw();
  }
}

/**
 * Display detected contours' bounding boxes
 */
void displayContoursBoundingBoxes() {
  for (int i = 0; i < contours.size(); i += 1) {
    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();

    if (r.width < blobSizeThreshold || r.height < blobSizeThreshold) {
      continue;
    }

    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }
}

/**
 * Initial setup
 */
void setup() {
  size(1160, 720, P2D);
  // background(255, 255, 255);
  // frameRate();
  // Setup camera.
  // printArray(Capture.list()); // Use this to check available cameras.
  video = new Capture(this, frameWidth, frameHeight);
  // video = new Capture(this, frameWidth, frameHeight, "USB 2.0 Camera");
  video.start();

  // Configure openCV
  opencv = new OpenCV(this, frameWidth, frameHeight);
  // Enable motion tracking by subtracting background
  opencv.startBackgroundSubtraction(10, 3, 0.5);
  contours = new ArrayList<Contour>();

  // Blobs list
  blobList = new ArrayList<Blob>();

  // Initialise controls
  cp5 = new ControlP5(this);
  initControls();

  // Initialise empty image – this is needed as we are using captureEvent()
  src = createImage(frameWidth, frameHeight, RGB);
  adjustedImage = createImage(frameWidth, frameHeight, RGB);
  processedImage = createImage(frameWidth, frameHeight, RGB);
  contoursImage = createImage(frameWidth, frameHeight, RGB);
}

/**
 * Process video frame
 */
void captureEvent(Capture video) {
  video.read();
  opencv.loadImage(video);

  // Store original frame
  src = opencv.getSnapshot();

  // Apply image adjustments (for now, only contrast)
  opencv.contrast(contrast);

  // Store adjusted frame
  adjustedImage = opencv.getSnapshot();

  // Update background for motion tracking
  opencv.updateBackground();

  // Apply threshold / adaptive threshold
  // Adaptive threshold
  if (useAdaptiveThreshold) {  
    // Block size must be odd and greater than 3
    if (thresholdBlockSize % 2 == 0) {
      thresholdBlockSize += 1;
    }

    if (thresholdBlockSize < 3) {
      thresholdBlockSize = 3;
    }

    opencv.adaptiveThreshold(thresholdBlockSize, thresholdConstant);

    // Basic threshold - range [0, 255]
  } else {
    opencv.threshold(threshold);
  }

  // Reduce noise - Dilate and erode to close holes
  opencv.dilate();
  opencv.erode();

  // Blur
  opencv.blur(blurSize);

  // Store processed frame
  processedImage = opencv.getSnapshot();

  // Find contours
  detectBlobs();

  // Store frame with contours
  contoursImage = opencv.getSnapshot();
}

/**
 * Draw output
 */
void draw() {
  pushMatrix();
  // Leave space for controls
    translate(width - src.width, 0);
  // Display frames
   //displayImages();

    // Display active area
    //pushMatrix();
    //  scale(2);
    //  translate(-src.width / 2, 0);
      
    //// displayContours();
    //// displayContoursBoundingBoxes();
    
      if (frameCount >= 150) {
        displayBlobs();
      }
    //popMatrix();
  popMatrix();
}
