import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;
import 'point.dart';

// TODO: Add documentation...

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<_Paintable> _streamController;

  /// The density (number of points) per window area.
  /// Per (x * x) pixels we want z points.
  static const double _pointDensity = 1 / (200 * 200);
  static const int _pointsMax = 256;
  _Paintable _paintable;

  BuildContext _context;

  @override
  void initState() {
    super.initState();

    // Duration does not matter here since we repeat it.
    // Setting it to 1 hour so that we skip unnecessary function calls.
    _animationController =
        AnimationController(vsync: this, duration: Duration(hours: 1));
    _animationController.addListener(() {
      _renderFrame();
    });

    _streamController = StreamController<_Paintable>();
    _paintable = _Paintable();

    // Start animation (+physics)
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    var size = MediaQuery.of(_context).size;

    return GestureDetector(
      onPanStart: (details) => _addUserPoint(details.localPosition),
      onPanUpdate: (details) => _addUserPoint(details.localPosition),
      onPanEnd: (_) => _addUserPointToList(),
      child: StreamBuilder<_Paintable>(
        stream: _streamController.stream,
        builder: (context, snapshot) => SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: _BackdropPainter(context, snapshot.data),
            willChange: true,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _streamController.close();
    super.dispose();
  }

  void _renderFrame() {
    _regulateAmountOfPoints(_paintable._points);
    PointEngineDelegate.updatePoints(_paintable._points, _context);
    _streamController.add(_paintable);
  }

  void _regulateAmountOfPoints(List<Point> points) {
    // Determine suitable max amount of points depending on window size.
    var size = MediaQuery.of(_context).size;
    var pointsMax = (size.width * size.height * _pointDensity).toInt();
    pointsMax = min(pointsMax, _pointsMax);

    // Either add points if point density is not reached, 
    // or remove points if we have too many.
    for (int i = min(pointsMax, points.length); i < max(pointsMax, points.length); ++i) {
      if (i < pointsMax) {
        // Generate
        points
            .add(Point.getRandomPoint(_context));
      } else {
        // Delete
        points.removeRange(i, points.length);
      }
    }
  }

  void _addUserPoint(Offset localPosition) {
    _paintable._userPoint = Point(localPosition, Offset(0, 0), Point.radiusMax);
  }

  void _addUserPointToList() {
    _paintable._points.replaceRange(0, 0, [_paintable._userPoint]);
    _paintable._userPoint = null;
  }
}

class _Paintable {
  List<Point> _points = <Point>[];
  Point _userPoint;
}

class _BackdropPainter extends CustomPainter {
  static final _backgroundBrush = Paint()
    ..color = backdropTheme.backgroundColor;
  int _lineDistanceLimit = 200;
  _Paintable _paintable;
  BuildContext _context;

  _BackdropPainter(this._context, this._paintable);

  @override
  void paint(Canvas canvas, Size _) {
    var size = MediaQuery.of(_context).size;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        _backgroundBrush);

    // For each point
    for (int current = 0; current < _paintable._points.length; ++current) {
      drawLinesToAllOtherPoints(canvas, _paintable._points[current]);
      _paintable._points[current].draw(canvas, size);
    }

    // Extra for user input
    if (_paintable._userPoint != null) {
      drawLinesToAllOtherPoints(canvas, _paintable._userPoint);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate != this;
  }

  void drawLinesToAllOtherPoints(Canvas canvas, Point point) {
    var linePaint = Paint();
    for (final other in _paintable._points) {
      if (other == point) {
        continue;
      }

      var distance = (point.position-other.position).distance;
      linePaint.color = Color.fromRGBO(
        backdropTheme.foregroundColor.red,
        backdropTheme.foregroundColor.green,
        backdropTheme.foregroundColor.blue,
        (distance < _lineDistanceLimit) ? 1.0 - distance / _lineDistanceLimit : 0);

      canvas.drawLine(point.position, other.position, linePaint);
    }
  }
}
