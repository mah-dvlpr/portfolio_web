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
    // TODO: The framework's unbounded variant of AnimationController is a bit 
    // odd as of now (1.27.0-4.0.pre). Doing this instead. V
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.addListener(() {
      _notifyPainter();
    });
    _streamController = StreamController<List<Point>>();
    _points = <Point>[];

    // Start animation
    _animationController.repeat();
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
