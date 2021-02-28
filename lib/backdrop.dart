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
    _animationController = AnimationController.unbounded(
        vsync: this, duration: Duration(seconds: 1));
    _animationController.addListener(() {
      _notifyPainter();
    });
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Point {}
