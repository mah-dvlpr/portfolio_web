import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;

class Point {
  DateTime dateTime;
  final pointBrush = Paint()..color = backdropTheme.foregroundColor;
  static final random = Random();

  /// Current position on canvas.
  Offset position;

  /// Force (+/-) in terms of x/y coordinates of current position on canvas.
  Offset force;

  /// A Point grows...
  static const radiusNumberOfIncrements = 32;
  static const double radiusMin = 0.5;
  double radiusCurrent = radiusMin;
  double radiusTarget;

  // Currently purely based on radius
  double mass;

  Point._(this.position, this.force, this.radiusTarget) {
    dateTime = DateTime.now();
    mass = this.radiusCurrent;
  }

  static Point getRandomPoint(double maxRadius) {
    var position = Offset(random.nextDouble() * window.physicalSize.width,
                          random.nextDouble() * window.physicalSize.height);
    var initialForce = Offset(0,0);
    var radiusTarget = (random.nextDouble() * maxRadius + radiusMin) % maxRadius;

    return Point._(position, initialForce, radiusTarget);
  }

  void draw(Canvas canvas, Size canvasSize) {
    if (DateTime.now().difference(dateTime).inMilliseconds > backdropTheme.tickMilliTime30fps &&
        radiusCurrent < radiusTarget) {
      dateTime = DateTime.now();
      radiusCurrent += min(radiusTarget / radiusNumberOfIncrements, radiusTarget);
    }
    canvas.drawCircle(position, radiusCurrent, pointBrush);
    mass = radiusCurrent;
  }
}

/// Utility class for handling physics of supplied points.
abstract class PointEngineDelegate {
  static DateTime dateTime = DateTime.now();
  static const maxForce = 1.0;
  static const maxRadius = 5.0; // TODO: Might be better to just have this as max mass?

  static updatePoints(List<Point> points) {
    if (DateTime.now().difference(dateTime).inMilliseconds < backdropTheme.tickMilliTime60fps) {
      return;
    }
    dateTime = DateTime.now();
    _updatePointSpeedPerAdjacentPoints(points);
    _updatePointPosition(points);
  }

  static double hypotenuseSquared(Point a, Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }

  static _updatePointSpeedPerAdjacentPoints(List<Point> points) {
    // For current object, update and apply force for every other object
    for (int current = 0; current < points.length - 1; ++current) {
      for (int other = current + 1; other < points.length; ++other) {
        if (_pointsAreNotTouching(points[current], points[other])) {
          _addMutualForce(points[current], points[other]);
        } else {
          points[other] = _combinePointsAndCreateNew(points[current], points[other]);
        }
      }

      _ifAboveMaxSlowDown(points[current]);
    }
  }

  static _updatePointPosition(List<Point> points) {
    for (int i = 0; i < points.length; ++i) {
      points[i].position += points[i].force;
      if (points[i].position.dx < 0 ||
          points[i].position.dx > window.physicalSize.width ||
          points[i].position.dy < 0 ||
          points[i].position.dy > window.physicalSize.height) {
        points[i] = Point.getRandomPoint(maxRadius);
      }
    }
  }

  static bool _pointsAreNotTouching(Point a, Point b) {
    return (hypotenuseSquared(a, b) >= pow(a.radiusCurrent + b.radiusCurrent, 2));
  }

  static Point _combinePointsAndCreateNew(Point a, Point b) {
    a.radiusTarget = max(a.radiusTarget, b.radiusTarget);
    a.mass = max(a.mass, b.mass);
    return Point.getRandomPoint(maxRadius);
  }

  static void _addMutualForce(Point a, Point b) {
    // Determine magnitude of attraction (some pseudo science here)
    var attraction = a.mass * b.mass / hypotenuseSquared(a, b);

    // Determine direction (based on the perspective of point 'a')
    var attractionX = (a.position.dx < b.position.dx) ? attraction : -attraction;
    var attractionY = (a.position.dy < b.position.dy) ? attraction : -attraction;
    
    // Apply attraction to each point
    var additiveForce = Offset(attractionX, attractionY);
    a.force += additiveForce;
    b.force += -additiveForce; // Equal, but opposite direction
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