import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<List<_Point>> _streamController;

  static const int pointsMax = 50;
  List<_Point> _points;

  @override
  void initState() {
    super.initState();
    // TODO: The framework's unbounded variant of AnimationController is a bit
    // odd as of now (1.27.0-4.0.pre). Doing this instead. V
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.addListener(() {
      _notifyPainter();
    });
    _streamController = StreamController<List<_Point>>();
    _points = <_Point>[];

    _generateRandomPoints(_points);

    // Start animation
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_Point>>(
      stream: _streamController.stream,
      builder: (_, snapshot) => CustomPaint(
        painter: _BackdropPainter(snapshot.data),
        willChange: true,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _streamController.close();
    super.dispose();
  }

  void _notifyPainter() {
    _PhysicsDelegate.updatePoints(_points);
    _streamController.add(_points);
  }

  /// Has to be called AFTER the first paint.
  void _generateRandomPoints(List<_Point> points) {
    for (int i = 0; i < pointsMax; ++i) {
      _points.add(_Point.getRandomPoint());
    }
  }
}

class _BackdropPainter extends CustomPainter {
  List<_Point> _points;

  _BackdropPainter(this._points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.largest, Paint()..color = Colors.cyan[900]);

    for (var point in _points) {
      canvas.drawCircle(point.position, point.size, point.pointBrush);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return true;
  }
}

class _Point {
  /// TODO: Arbitray value for now...
  static const speedMax = 50;
  static const sizeMax = 4;
  static final random = Random();

  final pointBrush = Paint()..color = Colors.lightBlue[50];

  /// Current position on canvas.
  Offset position;

  /// Speed (+/-) in terms of x/y coordinates of current position on canvas.
  Offset speed;

  double size;

  _Point(this.position, this.speed, this.size);

  static _Point getRandomPoint() {
    return _Point(
        Offset(random.nextDouble() * window.physicalSize.width,
            random.nextDouble() * window.physicalSize.height),
        Offset(random.nextDouble() * speedMax, random.nextDouble() * speedMax),
        random.nextDouble() * sizeMax);
  }
}

/// Utility class for handling physics of supplied points.
class _PhysicsDelegate {
  static final double G = 6.67384 * pow(10, -11);
  static DateTime dateTime;

  _PhysicsDelegate._();

  static updatePoints(List<_Point> points) {
    if (dateTime != null && DateTime.now().difference(dateTime).inSeconds < 1) {
      return;
    }
    dateTime = DateTime.now();
    _updatePointSpeedPerAdjacentPoints(points);
    _updatePointPosition(points);
  }

  static _updatePointSpeedPerAdjacentPoints(List<_Point> points) {
    for (int currentPointIndex = 0; currentPointIndex < points.length - 1; ++currentPointIndex) {
      var currentPoint = points[currentPointIndex];
      double currentPointMass = currentPoint.size; // TODO: Doing this for now, might change later
      for (int otherPointIndex = currentPointIndex + 1; otherPointIndex < points.length; ++otherPointIndex) {
        var otherPoint = points[otherPointIndex];
        double otherPointMass = points[otherPointIndex].size; // TODO: Doing this for now, might change later

        var attraction = G * currentPointMass * otherPointMass / _hypotenuseSquared(currentPoint, otherPoint);
        currentPoint.speed += Offset(attraction, attraction);
      }
    }
  }

  static _updatePointPosition(List<_Point> points) {
    for (var point in points) {
      point.position += point.speed;
    }
  }

  static double _hypotenuseSquared(_Point a, _Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }
}