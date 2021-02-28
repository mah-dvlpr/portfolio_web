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
        AnimationController(vsync: this, duration: Duration(seconds: 100));
    _animationController.addListener(() => _notifyListeners());
    _streamController = StreamController<List<_Point>>();
    _points = <_Point>[];
    _generateRandomPoints(_points);

    // Start animation (+physics)
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

  void _notifyListeners() {
    _PhysicsDelegate.updatePoints(_points);
    _streamController.add(_points);
  }

  /// Has to be called AFTER the first paint.
  void _generateRandomPoints(List<_Point> points) {
    for (int i = 0; i < pointsMax; ++i) {
      _points.add(_Point.getRandomPoint(_PhysicsDelegate()));
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
  final pointBrush = Paint()..color = Colors.lightBlue[50];

  /// Current position on canvas.
  Offset position;

  /// Speed (+/-) in terms of x/y coordinates of current position on canvas.
  Offset speed;

  double size;

  _Point(this.position, this.speed, this.size);

  static _Point getRandomPoint(_PhysicsDelegate physics) {
    return _Point(
        Offset(physics.random.nextDouble() * window.physicalSize.width,
            physics.random.nextDouble() * window.physicalSize.height),
        Offset(0, 0),
        // Offset((physics.random.nextDouble() * physics.speedMax) - physics.speedMax / 2, 
        //     (physics.random.nextDouble() * physics.speedMax) - physics.speedMax / 2),
        physics.random.nextDouble() * physics.sizeMax + 1);
  }
}

/// Utility class for handling physics of supplied points.
class _PhysicsDelegate {
  static DateTime dateTime;
  static const _speedMax = 2.0;
  static const _sizeMax = 2.0;
  static final _random = Random();

  _PhysicsDelegate();

  // Just so that this delegate can be passed as an argument
  double get speedMax => _PhysicsDelegate._speedMax;
  double get sizeMax => _PhysicsDelegate._sizeMax;
  Random get random => _PhysicsDelegate._random;

  static updatePoints(List<_Point> points) {
    // Note: < 16 ~= 60 fps
    if (dateTime != null && DateTime.now().difference(dateTime).inMilliseconds < 16) {
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

  static _updatePointPosition(List<_Point> points) {
    for (int i = 0; i < points.length; ++i) {
      points[i].position += points[i].speed;
      if (points[i].position.dx < 0                           ||
          points[i].position.dx > window.physicalSize.width   ||
          points[i].position.dy < 0                           ||
          points[i].position.dy > window.physicalSize.height) {
        points[i] = _Point.getRandomPoint(_PhysicsDelegate());
      }
    }
  }

  static double _hypotenuseSquared(_Point a, _Point b) {
    var dx = pow((a.position.dx - b.position.dx).abs(), 2);
    var dy = pow((a.position.dy - b.position.dy).abs(), 2);
    return dx + dy;
  }
}