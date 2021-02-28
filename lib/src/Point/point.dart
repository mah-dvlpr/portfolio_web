import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// TODO: Fix this class!
class Point {
  final pointBrush = Paint()..color = Colors.lightBlue[50];

  /// Current position on canvas.
  Offset position;

  /// Speed (+/-) in terms of x/y coordinates of current position on canvas.
  Offset speed;

  /// A Point grows from it's point of creation, [sizeInit], and grows to [sizeTarget].
  double sizeInit;
  double sizeTarget;

  Point._(this.position, this.speed, this.sizeInit, this.sizeTarget);

  static Point getRandomPoint(PhysicsDelegate physics, BuildContext context) {
    return Point._(
        Offset(physics.random.nextDouble() * MediaQuery.of(context).size.width,
            physics.random.nextDouble() * MediaQuery.of(context).size.height),
        Offset(0, 0),
        // Offset((physics.random.nextDouble() * physics.speedMax) - physics.speedMax / 2, 
        //     (physics.random.nextDouble() * physics.speedMax) - physics.speedMax / 2),
        physics.random.nextDouble() * physics.sizeMax + 1);
  }

  void draw(Canvas canvas, Size canvasSize) {
    canvas.drawCircle(position, size, pointBrush);
  }
}

/// TODO: Fix this class!
/// Utility class for handling physics of supplied points.
class PhysicsDelegate {
  static DateTime dateTime;
  static const _speedMax = 2.0;
  static const _sizeMax = 2.0;
  static final _random = Random();

  PhysicsDelegate();

  // Duplicating fields, but this is so that this delegate can be passed as an argument
  double get speedMax => PhysicsDelegate._speedMax;
  double get sizeMax => PhysicsDelegate._sizeMax;
  Random get random => PhysicsDelegate._random;

  static updatePoints(List<Point> points, BuildContext context) {
    // Note: < 16 ~= 60 fps
    if (dateTime != null && DateTime.now().difference(dateTime).inMilliseconds < 16) {
      return;
    }
    dateTime = DateTime.now();
    _updatePointSpeedPerAdjacentPoints(points);
    _updatePointPosition(points, context);
  }

  static _updatePointSpeedPerAdjacentPoints(List<Point> points) {
    for (int currentPointIndex = 0; currentPointIndex < points.length - 1; ++currentPointIndex) {
      var currentPoint = points[currentPointIndex];
      double currentPointMass = currentPoint.size; // TODO: Doing this for now, might change later
      
      for (int otherPointIndex = currentPointIndex + 1; otherPointIndex < points.length; ++otherPointIndex) {
        var otherPoint = points[otherPointIndex];
        double otherPointMass = otherPoint.size; // TODO: Doing this for now, might change later

        var attraction = currentPointMass * otherPointMass / _hypotenuseSquared(currentPoint, otherPoint);
        var attractionX = (currentPoint.position.dx < otherPoint.position.dx) ? attraction : -attraction;
        var attractionY = (currentPoint.position.dy < otherPoint.position.dy) ? attraction : -attraction;
        currentPoint.speed += Offset(attractionX, attractionY);
      }

      // Make sure we don't reach lightspeed!
      if (currentPoint.speed.dx.abs() > _speedMax) {
        currentPoint.speed = Offset(_speedMax, currentPoint.speed.dy);
      }
      if (currentPoint.speed.dy.abs() > _speedMax) {
        currentPoint.speed = Offset(currentPoint.speed.dx, _speedMax);
      }
    }
  }

  static _updatePointPosition(List<Point> points, context) {
    for (int i = 0; i < points.length; ++i) {
      points[i].position += points[i].speed;
      if (points[i].position.dx < 0 ||
          points[i].position.dx > MediaQuery.of(context).size.width ||
          points[i].position.dy < 0 ||
          points[i].position.dy > MediaQuery.of(context).size.height) {
        points[i] = Point.getRandomPoint(PhysicsDelegate(), context);
      }
    }
  }

  static double _hypotenuseSquared(Point a, Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }
}