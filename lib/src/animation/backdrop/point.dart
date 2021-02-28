import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class Point {
  DateTime dateTime;
  final pointBrush = Paint()..color = Colors.lightBlue[50];
  static final random = Random();

  /// Current position on canvas.
  Offset position;

  /// Force (+/-) in terms of x/y coordinates of current position on canvas.
  Offset force;

  /// A Point grows from [sizeTarget.first] to [sizeTarget.last].
  static const sizeTargetElements = 32;
  List<double> sizeTarget;
  int sizeTargetIndex = 0;

  // Currently purely based on size
  double mass;

  Point._(this.position, this.force, double sizeTarget) {
    dateTime = DateTime.now();
    this.sizeTarget = <double>[];
    for (double i = 0.0; i <= sizeTarget; i += sizeTarget / sizeTargetElements) {
      this.sizeTarget.add(i);
    }
    mass = this.sizeTarget.first;
  }

  static Point getRandomPoint(BuildContext context, double maxForce, double maxSize) {
    var position = Offset(random.nextDouble() * MediaQuery.of(context).size.width,
                          random.nextDouble() * MediaQuery.of(context).size.height);
    var initialForce = Offset((random.nextDouble() * maxForce) - maxForce / 2, 
                              (random.nextDouble() * maxForce) - maxForce / 2);
    var sizeTarget = random.nextDouble() * maxSize;

    return Point._(position, initialForce, sizeTarget);
  }

  void draw(Canvas canvas, Size canvasSize) {
    if (sizeTargetIndex < sizeTargetElements - 1 &&
        DateTime.now().difference(dateTime).inMilliseconds > 32) {
      ++sizeTargetIndex;
      dateTime = DateTime.now();
    }
    canvas.drawCircle(position, sizeTarget[sizeTargetIndex], pointBrush);
    mass = this.sizeTarget[sizeTargetIndex];
  }
}

/// Utility class for handling physics of supplied points.
class PointEngineDelegate {
  static DateTime dateTime;
  static const maxForce = 2.0;
  static const maxSize = 10.0; // TODO: Might be better to just have this as max mass?

  PointEngineDelegate();

  static updatePoints(List<Point> points, BuildContext context) {
    // Note: < 16 ~= 60 fps, < 32 ~= 30 fps
    if (dateTime != null && DateTime.now().difference(dateTime).inMilliseconds < 16) {
      return;
    }
    dateTime = DateTime.now();
    _updatePointSpeedPerAdjacentPoints(points);
    _updatePointPosition(points, context);
  }

  static _updatePointSpeedPerAdjacentPoints(List<Point> points) {
    // For current object, update and apply force for every other object
    for (int current = 0; current < points.length - 1; ++current) {
      for (int other = current + 1; other < points.length; ++other) {
        _addMutualForce(points[current], points[other]);
      }
    }
  }

  static _updatePointPosition(List<Point> points, context) {
    for (int i = 0; i < points.length; ++i) {
      points[i].position += points[i].force;
      if (points[i].position.dx < 0 ||
          points[i].position.dx > MediaQuery.of(context).size.width ||
          points[i].position.dy < 0 ||
          points[i].position.dy > MediaQuery.of(context).size.height) {
        points[i] = Point.getRandomPoint(context, maxForce, maxSize);
      }
    }
  }

  static Offset _addMutualForce(Point a, Point b) {
    // Determine magnitude of attraction
    var attraction = a.mass * b.mass / _hypotenuseSquared(a, b);

    // Determine direction (based on the perspective of point 'a')
    var attractionX = (a.position.dx < b.position.dx) ? attraction : -attraction;
    var attractionY = (a.position.dy < b.position.dy) ? attraction : -attraction;
    
    // Apply attraction to each point
    var additiveForce = Offset(attractionX, attractionY);
    if (_isBelowForceLimit(a)) { // Max force limit
      a.force += additiveForce;
    }
    if (_isBelowForceLimit(b)) { // Max force limit
      b.force += -additiveForce; // Equal, but opposite direction
    }
  }

  static double _hypotenuseSquared(Point a, Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }

  static bool _isBelowForceLimit(Point a) {
    return sqrt(pow(a.force.dx.abs(), 2) + pow(a.force.dy.abs(), 2)) < maxForce;
  }
}