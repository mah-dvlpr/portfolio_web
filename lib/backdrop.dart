import 'dart:async';

import 'package:flutter/material.dart';

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<List<Point>> _streamController;
  List<Point> _points;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.addStatusListener((status) {
      // Below works if you want a static time every second, but not the best
      if (status == AnimationStatus.completed) {
        _notifyPainter();
        _animationController.reset();
        _animationController.forward();
      }
    });
    _animationController.forward();
    _streamController = StreamController<List<Point>>();
    _points = <Point>[];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Point>>(
      stream: _streamController.stream,
      builder: (_, snapshot) => CustomPaint(
        painter: BackdropPainter(snapshot.data),
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

  _notifyPainter() {
    _points.add(Point());
    _streamController.add(_points);
  }
}

class BackdropPainter extends CustomPainter {
  List<Point> _points;

  BackdropPainter(this._points);

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    print('hej');
  }

  @override
  bool shouldRepaint(BackdropPainter oldDelegate) {
    return true;
  }
}

class Point {}
