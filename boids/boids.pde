int numBoids = 100;
Boid[] boids;
boolean scatterMode = false; // To track if scatter mode is active
int scatterTimer = 0; // Timer to manage scatter duration
int scatterDuration = 2000; // Scatter duration in milliseconds
float cursorRepulsionRadius = 64; // Radius around the cursor to repel boids

void setup() {
  size(800, 800);
  background(0);
  boids = new Boid[numBoids];
  for (int i = 0; i < numBoids; i++) {
    boids[i] = new Boid(random(width), random(height));
  }
}

void draw() {
  // Draw a semi-transparent rectangle to fade the trails
  fill(30, 30, 30, 16);
  noStroke();
  rect(0, 0, width, height);

  if (scatterMode) {
    if (millis() - scatterTimer > scatterDuration) {
      scatterMode = false; // End scatter mode
      resetBoidVelocities(); // Reset velocities to random directions
    }
  }

  for (Boid b : boids) {
    if (scatterMode) {
      b.scatter(boids); // Scatter behavior
    } else {
      b.update(boids); // Regular boid behavior
    }
    b.show();
  }
}

void keyPressed() {
  if (key == ' ') { // Detect space bar
    scatterMode = true;
    scatterTimer = millis(); // Start scatter timer
  }
}

// Reset boid velocities to random directions
void resetBoidVelocities() {
  for (Boid b : boids) {
    b.velocity = PVector.random2D();
    b.velocity.setMag(random(1, b.maxSpeed)); // Assign random speed
  }
}

class Boid {
  PVector position;
  PVector velocity;
  PVector acceleration;
  color boidColor;
  float maxForce = 0.05;
  float maxSpeed = 2;
  float perceptionRadius = 50;

  Boid(float x, float y) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.setMag(random(1, maxSpeed));
    acceleration = new PVector();
    boidColor = color(random(255), random(255), random(255));
  }

  void update(Boid[] boids) {
    acceleration.set(0, 0);

    if (mousePressed && dist(position.x, position.y, mouseX, mouseY) < cursorRepulsionRadius) {
      avoidCursor(); // Apply repulsion from the cursor
    } else {
      PVector alignment = align(boids);
      PVector cohesion = cohere(boids);
      PVector separation = separate(boids);

      // Weight the forces
      alignment.mult(1.5);
      cohesion.mult(1.0);
      separation.mult(1.5);

      acceleration.add(alignment);
      acceleration.add(cohesion);
      acceleration.add(separation);
    }

    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);

    edges();
  }

  void avoidCursor() {
    PVector cursor = new PVector(mouseX, mouseY);
    PVector diff = PVector.sub(position, cursor);
    float d = diff.mag();
    if (d < cursorRepulsionRadius) {
      diff.setMag(maxSpeed);
      diff.sub(velocity);
      diff.limit(maxForce);
      acceleration.add(diff);
    }
  }

  void scatter(Boid[] boids) {
    acceleration.set(0, 0);
    PVector escape = new PVector();

    // Compute scatter force
    for (Boid other : boids) {
      if (other != this) {
        float d = dist(position.x, position.y, other.position.x, other.position.y);
        if (d < perceptionRadius) {
          PVector diff = PVector.sub(position, other.position);
          diff.div(d * d); // Stronger force the closer the boids
          escape.add(diff);
        }
      }
    }

    escape.setMag(maxSpeed);
    escape.sub(velocity);
    escape.limit(maxForce);

    acceleration.add(escape);

    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);

    edges();
  }

  void show() {
    fill(boidColor);
    noStroke();
    ellipse(position.x, position.y, 2, 2);
  }

  void edges() {
    if (position.x > width) position.x = 0;
    if (position.x < 0) position.x = width;
    if (position.y > height) position.y = 0;
    if (position.y < 0) position.y = height;
  }

  PVector align(Boid[] boids) {
    PVector steering = new PVector();
    int total = 0;
    for (Boid other : boids) {
      float d = dist(position.x, position.y, other.position.x, other.position.y);
      if (other != this && d < perceptionRadius) {
        steering.add(other.velocity);
        total++;
      }
    }
    if (total > 0) {
      steering.div((float) total);
      steering.setMag(maxSpeed);
      steering.sub(velocity);
      steering.limit(maxForce);
    }
    return steering;
  }

  PVector cohere(Boid[] boids) {
    PVector steering = new PVector();
    int total = 0;
    for (Boid other : boids) {
      float d = dist(position.x, position.y, other.position.x, other.position.y);
      if (other != this && d < perceptionRadius) {
        steering.add(other.position);
        total++;
      }
    }
    if (total > 0) {
      steering.div((float) total);
      steering.sub(position);
      steering.setMag(maxSpeed);
      steering.sub(velocity);
      steering.limit(maxForce);
    }
    return steering;
  }

  PVector separate(Boid[] boids) {
    PVector steering = new PVector();
    int total = 0;
    for (Boid other : boids) {
      float d = dist(position.x, position.y, other.position.x, other.position.y);
      if (other != this && d < perceptionRadius / 2) {
        PVector diff = PVector.sub(position, other.position);
        diff.div(d * d);
        steering.add(diff);
        total++;
      }
    }
    if (total > 0) {
      steering.div((float) total);
      steering.setMag(maxSpeed);
      steering.sub(velocity);
      steering.limit(maxForce);
    }
    return steering;
  }
}
