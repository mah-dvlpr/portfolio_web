import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;
import '../../utility.dart';

class Point {
  static final random = Random();
  final pointBrush = Paint()..color = backdropTheme.foregroundColor;
  DateTime dateTime;

  /// Current position on canvas.
  Offset position;

  /// Velocity (+/-) in terms of x/y coordinates of current position on canvas.
  static const double velocityMax = 1.0;
  Offset velocity;

  /// A Point grows...
  static const radiusNumberOfIncrements = 32;
  static const double radiusMin = 1.0;
  double radiusCurrent;
  double radiusMax;

  // Currently purely based on radius
  double mass;

  Point(this.position, this.velocity, double radiusMax) {
    dateTime = DateTime.now();
    this.radiusMax = random.nextDouble() * (radiusMax - radiusMin) + radiusMin;
    this.radiusCurrent = radiusMin;
    mass = this.radiusCurrent;
  }

  static Point getRandomPoint(double radiusMax, BuildContext context) {
    var size = MediaQuery.of(context).size;
    var position = Offset(
        random.nextDouble() * size.width, random.nextDouble() * size.height);

    // Pythagorean theorem to get missing Cathetus
    // Note: Realized that this is not really necessary, but if you want to have
    // "correct" values, even for diagonal movement, this is the way to do it.
    var c = random.nextDouble() * velocityMax;
    var a = random.nextDouble() * c;
    var b = sqrt(pow(c, 2) - pow(a, 2));
    a = random.nextBool() ? -a : a;
    b = random.nextBool() ? -b : b;
    var velocity = Offset(a, b);

    return Point(position, velocity, radiusMax);
  }

  void draw(Canvas canvas, Size canvasSize) {
    if (DateTime.now().difference(dateTime).inMilliseconds >
            backdropTheme.tickMilliTime30fps &&
        radiusCurrent < radiusMax) {
      dateTime = DateTime.now();
      radiusCurrent +=
          min(radiusMax / radiusNumberOfIncrements, radiusMax);
    }

    canvas.drawCircle(position, radiusCurrent, pointBrush);
    mass = radiusCurrent;
  }
}

/// Utility class for handling physics of supplied points.
abstract class PointEngineDelegate {
  static DateTime dateTime = DateTime.now();
  // static const maxForce = 1.0;
  static const maxRadius =
      3.0; // TODO: Might be better to just have this as max mass?

  static updatePoints(List<Point> points, BuildContext context) {
    if (DateTime.now().difference(dateTime).inMilliseconds <
        backdropTheme.tickMilliTime60fps) {
      return;
    }
    dateTime = DateTime.now();
    _updatePointSpeedPerAdjacentPoints(points, context);
    _updatePointPosition(points, context);
  }

  static double hypotenuseSquared(Point a, Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }

  static _updatePointSpeedPerAdjacentPoints(
      List<Point> points, BuildContext context) {
    // For current object, update and apply force for every other object
    for (int current = 0; current < points.length - 1; ++current) {
      for (int other = current + 1; other < points.length; ++other) {
        if (_pointsAreNotTouching(points[current], points[other])) {
          _addMutualForce(points[current], points[other]);
        } else {
          _combinePoints(points, current, other, context);
        }
      }

      _ifAboveMaxSlowDown(points[current]);
    }
  }

  static _updatePointPosition(List<Point> points, BuildContext context) {
    var size = MediaQuery.of(context).size;

    for (int i = 0; i < points.length; ++i) {
      points[i].position += points[i].velocity;
      if (points[i].position.dx < 0 ||
          points[i].position.dx > size.width ||
          points[i].position.dy < 0 ||
          points[i].position.dy > size.height) {
        points.removeAt(i);
      }
    }
  }

  static bool _pointsAreNotTouching(Point a, Point b) {
    return (hypotenuseSquared(a, b) >=
        pow(a.radiusCurrent + b.radiusCurrent, 2));
  }

  static void _combinePoints(
      List<Point> points, int a, int b, BuildContext context) {
    points[a].radiusMax = max(points[a].radiusMax, points[b].radiusMax);
    points[a].mass = max(points[a].mass, points[b].mass);
    points.removeAt(b);
  }

  static void _addMutualForce(Point a, Point b) {
    // Determine magnitude of attraction (some pseudo science here)
    var attraction = 3 * a.mass * b.mass / hypotenuseSquared(a, b);

    // Determine direction (based on the perspective of point 'a')
    var attractionX =
        (a.position.dx < b.position.dx) ? attraction : -attraction;
    var attractionY =
        (a.position.dy < b.position.dy) ? attraction : -attraction;

    // Apply attraction to each point
    var additiveForce = Offset(attractionX, attractionY);
    a.velocity += additiveForce;
    b.velocity += -additiveForce; // Equal, but opposite direction
  }

  static void _ifAboveMaxSlowDown(Point a) {
    // // Slow it down gradually
    // if (a.force.dx > 0) {
    //   a.force -= Offset(a.force.dx - maxForce, a.force.dy);
    // } else {
    //   a.force += Offset(a.force.dx * 0.8, a.force.dy);
    // }
    // if (a.force.dy > maxForce) { a.force = Offset(a.force.dx, a.force.dy * 0.8); }
  }
}
