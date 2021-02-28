import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../Point/point.dart';

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<List<Point>> _streamController;

  static const int _pointsMax = 2;
  List<Point> _points;

  @override
  void initState() {
    super.initState();

    // TODO: The framework's unbounded variant of AnimationController is a bit
    // odd as of now (1.27.0-4.0.pre). Doing this instead. V
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 100));
    _animationController.addListener(() {
      _notifyListeners();
    });

    _streamController = StreamController<List<Point>>();
    _points = <Point>[];

    // Start animation (+physics)
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Point>>(
      stream: _streamController.stream,
      builder: (_, snapshot) => CustomPaint(
        painter: _BackdropPainter(snapshot.data),
        willChange: true,
        isComplex: true,
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
    _generateRandomPoints(_points);
    PhysicsDelegate.updatePoints(_points, context);
    _streamController.add(_points);
  }

  /// Will only generate points if list is not filled with [_pointsMax].
  void _generateRandomPoints(List<Point> points) {
    for (int i = points.length; i < _pointsMax; ++i) {
      _points.add(Point.getRandomPoint(PhysicsDelegate(), context));
    }
  }
}

class _BackdropPainter extends CustomPainter {
  static final backgroundBrush = Paint()..color = Colors.cyan[900];
  List<Point> _points;

  _BackdropPainter(this._points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.largest, backgroundBrush);

    for (var point in _points) {
      point.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return true;
  }
}