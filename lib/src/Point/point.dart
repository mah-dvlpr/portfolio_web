import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class Point {
  final pointBrush = Paint()..color = Colors.lightBlue[50];
  static final random = Random();

  /// Current position on canvas.
  Offset position;

  /// Force (+/-) in terms of x/y coordinates of current position on canvas.
  Offset force;

  /// A Point grows from [sizeTarget.first] to [sizeTarget.last].
  static const sizeTargetElements = 10;
  List<double> sizeTarget;

  Point._(this.position, this.force, double sizeTarget) {
    this.sizeTarget = <double>[];
    for (double i = 0; i >= sizeTarget; i += sizeTarget / sizeTargetElements) {
      this.sizeTarget.add(i);
    }
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
    canvas.drawCircle(position, , pointBrush);
  }
}

/// TODO: Fix this class!
/// Utility class for handling physics of supplied points.
class PointEngineDelegate {
  static DateTime dateTime;
  static const _speedMax = 2.0;
  static const _sizeMax = 2.0;
  static final _random = Random();

  PointEngineDelegate();

  // Duplicating fields, but this is so that this delegate can be passed as an argument
  double get speedMax => PointEngineDelegate._speedMax;
  double get sizeMax => PointEngineDelegate._sizeMax;
  Random get random => PointEngineDelegate._random;

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
        currentPoint.force += Offset(attractionX, attractionY);
      }

      // Make sure we don't reach lightspeed!
      if (currentPoint.force.dx.abs() > _speedMax) {
        currentPoint.force = Offset(_speedMax, currentPoint.force.dy);
      }
      if (currentPoint.force.dy.abs() > _speedMax) {
        currentPoint.force = Offset(currentPoint.force.dx, _speedMax);
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
        points[i] = Point.getRandomPoint(PointEngineDelegate(), context);
      }
    }
  }

  static double _hypotenuseSquared(Point a, Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }
}