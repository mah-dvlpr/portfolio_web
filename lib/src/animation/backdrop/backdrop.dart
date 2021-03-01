import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;
import 'point.dart';

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<List<Point>> _streamController;

  static const int _pointsMax = 50;
  List<Point> _points;

  @override
  void initState() {
    super.initState();

    print(backdropTheme.tickTime30fps);

    // TODO: The framework's unbounded variant of AnimationController is a bit
    // odd as of now (1.27.0-4.0.pre). Doing this instead. (AnimationController)
    // Note: Duration does not matter here since we repeat it.
    // Setting it to 1 hour so that we skip unnecessary function calls.
    _animationController =
        AnimationController(vsync: this, duration: Duration(hours: 1));
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
    PointEngineDelegate.updatePoints(_points, context);
    _streamController.add(_points);
  }

  /// Will only generate points if list is not filled with [_pointsMax].
  void _generateRandomPoints(List<Point> points) {
    for (int i = points.length; i < _pointsMax; ++i) {
      _points.add(Point.getRandomPoint(context, PointEngineDelegate.maxForce, PointEngineDelegate.maxRadius));
    }
  }
}

class _BackdropPainter extends CustomPainter {
  static final backgroundBrush = Paint()..color = backdropTheme.backgroundColor;
  static final lineStroke = Paint()..color = backdropTheme.foregroundColor;
  List<Point> _points;

  _BackdropPainter(this._points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.largest, backgroundBrush);

    for (int current = 0; current < _points.length - 1; ++current) {
      // Draw point itself
      _points[current].draw(canvas, size);
      for (int other = current + 1; other < _points.length; ++other) {
        // Draw lines between points deemed close enough
        if (_isCloseEnough(_points[current], _points[other])) {
          canvas.drawLine(_points[current].position, _points[other].position, lineStroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return true;
  }

  bool _isCloseEnough(Point a, Point b) {
    // 70 is just an arbitrary number. 70 times the radius of both points combined.
    return PointEngineDelegate.hypotenuseSquared(a, b) < 70 * pow((a.radiusTarget[a.radiusTargetIndex] + b.radiusTarget[b.radiusTargetIndex]), 2);
  }
}