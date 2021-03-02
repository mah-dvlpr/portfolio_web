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
  static const double radiusMax = 3.0;
  double radiusCurrent;
  double radiusTarget;

  /// Currently purely based on [radiusCurrent].
  double mass;

  /// [radiusMax] larger than the class static [radiusMax], will not be honored.
  Point(this.position, this.velocity, double radiusMax) {
    dateTime = DateTime.now();
    radiusMax = min(Point.radiusMax, radiusMax);
    this.radiusTarget = random.nextDouble() * (radiusMax - radiusMin) + radiusMin;
    this.radiusCurrent = radiusMin;
    mass = this.radiusCurrent;
  }

  static Point getRandomPoint(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var position = Offset(
        random.nextDouble() * size.width, random.nextDouble() * size.height);

    // Apply velocity/force in random direction.
    // Pythagorean theorem to get missing cathetus, and apply proper velocity.
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
    // Update time - Only render when wanted
    if (DateTime.now().difference(dateTime).inMilliseconds >
            backdropTheme.tickMilliTime30fps &&
        radiusCurrent < radiusTarget) {
      dateTime = DateTime.now();
      radiusCurrent +=
          min(radiusTarget / radiusNumberOfIncrements, radiusTarget);
    }

    canvas.drawCircle(position, radiusCurrent, pointBrush);
    mass = radiusCurrent;
  }
}

/// Utility class for handling physics of supplied points.
// TODO: Might be better to have  this as a kind of singleton to call it a 
// delegate?
abstract class PointEngineDelegate {
  static DateTime dateTime = DateTime.now();

  static updatePoints(List<Point> points, BuildContext context) {
    // Update time - Only render when wanted
    if (DateTime.now().difference(dateTime).inMilliseconds <
        backdropTheme.tickMilliTime60fps) {
      return;
    }
    dateTime = DateTime.now();

    // Update points
    _updatePointsVelocities(points, context);
    _updatePointsPositions(points, context);
  }

  static _updatePointsVelocities(
      List<Point> points, BuildContext context) {
    // For current point, update and apply force for every other point
    for (int current = 0; current < points.length - 1; ++current) {
      for (int other = current + 1; other < points.length; ++other) {
        if (_arePointsTouching(points[current], points[other])) {
          _combinePoints(points, current, other, context);
        } else {
          _addMutualForce(points[current], points[other]);
        }
      }
    }
  }

  static _updatePointsPositions(List<Point> points, BuildContext context) {
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

  static bool _arePointsTouching(Point a, Point b) {
    return (a.position-b.position).distanceSquared < pow(a.radiusCurrent + b.radiusCurrent, 2);
  }

  static void _combinePoints(
      List<Point> points, int a, int b, BuildContext context) {
    points[a].radiusTarget = max(points[a].radiusTarget, points[b].radiusTarget);
    points[a].mass = max(points[a].mass, points[b].mass);
    points.removeAt(b);
  }

  // TODO: Fix
  static void _addMutualForce(Point a, Point b) {
    // Determine magnitude of attraction (some pseudo science here)
    var attraction = 3 * a.mass * b.mass / (a.position+b.position).distanceSquared;

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
}
