import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;
import 'point.dart';
import '../../utility.dart';

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<List<Point>> _streamController;

  /// The density (number of points) per window area.
  /// Per 200 * 200 I want 1 point(s).
  static const double _pointDensity = 1 / (200 * 200);
  static const int _pointsMax = 3;
  List<Point> _points;

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

    _streamController = StreamController<List<Point>>();
    _points = <Point>[];

    // Start animation (+physics)
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    var size = MediaQuery.of(_context).size;

    return GestureDetector(
      onTapDown: (details) => _addPointTap(details.localPosition),
      onVerticalDragUpdate: (details) => _addPointDrag(details.localPosition),
      onHorizontalDragUpdate: (details) => _addPointDrag(details.localPosition),
      child: StreamBuilder<List<Point>>(
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
    _regulateAmountOfPoints(_points);
    PointEngineDelegate.updatePoints(_points, _context);
    _streamController.add(_points);
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
        _points
            .add(Point.getRandomPoint(PointEngineDelegate.maxRadius, _context));
      } else {
        // Delete
        _points.removeRange(i, points.length);
      }
    }
  }

  void _addPointTap(Offset localPosition) {
    _points.replaceRange(0,0,[Point(localPosition, Offset(0, 0), PointEngineDelegate.maxRadius)]);
  }

  void _addPointDrag(Offset localPosition) {
    
    _points.replaceRange(_points.length-1,_points.length-1,[Point(localPosition, Offset(0, 0), PointEngineDelegate.maxRadius)]);
  }
}

class _BackdropPainter extends CustomPainter {
  static final _backgroundBrush = Paint()
    ..color = backdropTheme.backgroundColor;
  var _linePaint = Paint();
  int _lineDistanceLimit = 200;
  List<Point> _points;
  BuildContext _context;

  _BackdropPainter(this._context, this._points);

  @override
  void paint(Canvas canvas, Size _) {
    var size = MediaQuery.of(_context).size;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        _backgroundBrush);

    for (int current = 0; current < _points.length; ++current) {
      // Draw point itself
      var p1 = _points[current];
      p1.draw(canvas, size);

      // Draw lines to all other points
      for (int other = current + 1; other < _points.length; ++other) {
        var p2 = _points[other];
        var distance = (p1.position-p2.position).distance;
        _linePaint.color = Color.fromRGBO(
          backdropTheme.foregroundColor.red,
          backdropTheme.foregroundColor.green,
          backdropTheme.foregroundColor.blue,
          (distance < _lineDistanceLimit) ? 1.0 - distance / _lineDistanceLimit : 0);

        canvas.drawLine(p1.position, p2.position, _linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate != this;
  }
}
