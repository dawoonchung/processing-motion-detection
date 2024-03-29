/**
 * Blob Class
 *
 * Based on this example by Daniel Shiffman:
 * http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
 * 
 * @author: Jordi Tost (@jorditost)
 * 
 * University of Applied Sciences Potsdam, 2014
 */

class Blob {

  private PApplet parent;

  // Contour
  public Contour contour;

  // Am I available to be matched?
  public boolean available;

  // Should I be deleted?
  public boolean delete;

  // How long should I live if I have disappeared?
  private int initTimer = 150; //127;
  public int timer;

  // Unique ID for each blob
  int id;
  int shape;

  // Make me
  Blob(PApplet parent, int id, Contour c) {
    this.parent = parent;
    this.id = id;
    this.contour = new Contour(parent, c.pointMat);
    this.shape = int(random(2));

    available = true;
    delete = false;

    timer = initTimer;
  }

  // Show me
  void display() {
    Rectangle r = contour.getBoundingBox();

    float opacity = map(timer, 0, initTimer, 0, 127);
    fill(0, 0, 255, 5);
    // stroke(0, 0, 255);
    noStroke();
    // rect(r.x, r.y, r.width, r.height);
    // ellipse(r.x, r.y, 25, 25);
    // fill(255, 2 * opacity);
    // textSize(26);
    // text(""+id, r.x+10, r.y+30);
    
    if (this.shape == 0) {
      rect(r.x - 12.5, r.y - 12.5, 25, 25);
    } else {
      ellipse(r.x, r.y, 25, 25);
    }
  }

  // Give me a new contour for this blob (shape, points, location, size)
  // Oooh, it would be nice to lerp here!
  void update(Contour newC) {

    contour = new Contour(parent, newC.pointMat);

    // Is there a way to update the contour's points without creating a new one?
    /*ArrayList<PVector> newPoints = newC.getPoints();
     Point[] inputPoints = new Point[newPoints.size()];
     
     for(int i = 0; i < newPoints.size(); i++){
     inputPoints[i] = new Point(newPoints.get(i).x, newPoints.get(i).y);
     }
     contour.loadPoints(inputPoints);*/

    timer = initTimer;
  }

  // Count me down, I am gone
  void countDown() {    
    timer--;
  }

  // I am deed, delete me
  boolean dead() {
    if (timer < 0) return true;
    return false;
  }

  public Rectangle getBoundingBox() {
    return contour.getBoundingBox();
  }
}
