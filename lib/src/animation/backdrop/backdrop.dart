import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;
import 'node.dart';

// TODO: Add documentation...

class BackdropAnimation extends StatefulWidget {
  @override
  _BackdropAnimationState createState() => _BackdropAnimationState();
}

class _BackdropAnimationState extends State<BackdropAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamController<_Paintable> _streamController;
  Size _size;

  /// The density (number of nodes) per window area.
  /// Per (x * x) pixels we want z nodes.
  static const double _nodeDensity = 1 / (200 * 200);
  static const int _nodesMax = 1000;
  _Paintable _paintable;

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
    _size = MediaQuery.of(context).size;
    _paintable.size = _size;

    return GestureDetector(
      onPanStart: (details) => _addUserNode(details.localPosition),
      onPanUpdate: (details) => _addUserNode(details.localPosition),
      onPanEnd: (_) => _addUserNodeToList(),
      child: StreamBuilder<_Paintable>(
        stream: _streamController.stream,
        builder: (_, snapshot) => SizedBox(
          width: _size.width,
          height: _size.height,
          child: CustomPaint(
            painter: _BackdropPainter(snapshot.data),
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
    NodeEngine.updateNodes(_paintable.nodes, _size);
    _regulateNodeAmount(_paintable.nodes);
    _streamController.add(_paintable);
  }

  void _regulateNodeAmount(List<Node> nodes) {
    // Determine suitable max amount of nodes depending on window size.
    var nodesMax = (_size.width * _size.height * _nodeDensity).toInt();
    nodesMax = min(nodesMax, _nodesMax);

    // Create nodes if list is not filled up until nodesMax
    // Replace any nodes that have been set to null.
    // If the list of nodes is too long (due to a window resize), shrink it.
    for (int i = 0; i < nodesMax; ++i) {
      if (i == nodes.length && i < nodesMax) {
        // Create new node.
        nodes.add(Node.getRandomNode(_size));
      }

      if (i < nodes.length && nodes[i] == null) {
        // Replace nullified node.
        nodes[i] = Node.getRandomNode(_size);
      }

      if (i == nodesMax - 1) {
        // Remove any extra nodes (after a window resize).
        nodes.removeRange(i, nodes.length);
        break;
      }
    }
  }

  void _addUserNode(Offset localPosition) {
    _paintable.userNode = Node(localPosition, Offset(0, 0), Node.radiusMax);
  }

  void _addUserNodeToList() {
    _paintable.nodes.replaceRange(0, 0, [_paintable.userNode]);
    _paintable.userNode = null;
  }
}

class _Paintable {
  List<Node> nodes = <Node>[];
  Node userNode;
  Size size;
}

class _BackdropPainter extends CustomPainter {
  static final _backgroundBrush = Paint()
    ..color = backdropTheme.backgroundColor;
  static final _lineDistanceLimit = 100;
  _Paintable _paintable;

  _BackdropPainter(this._paintable);

  @override
  void paint(Canvas canvas, Size _) {
    canvas.drawRect(
        Rect.fromCenter(
            center:
                Offset(_paintable.size.width / 2, _paintable.size.height / 2),
            width: _paintable.size.width,
            height: _paintable.size.height),
        _backgroundBrush);

    // For each node
    for (int i = 0; i < _paintable.nodes.length; ++i) {
      _drawLinesToAllOtherNodes(canvas, _paintable.nodes[i], i + 1);
      _paintable.nodes[i].draw(canvas, _paintable.size);
    }

    // Extra for user input
    if (_paintable.userNode != null) {
      _drawLinesToAllOtherNodes(canvas, _paintable.userNode, 0, true);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate != this;
  }

  void _drawLinesToAllOtherNodes(Canvas canvas, Node node, int indexStart,
      [bool userNode = false]) {
    var linePaint = Paint();
    for (int i = indexStart; i < _paintable.nodes.length; ++i) {
      var distance = (node.position - _paintable.nodes[i].position).distance;

      if (!userNode && distance >= _lineDistanceLimit) {
        continue;
      } else if (userNode && distance >= _lineDistanceLimit * 3) {
        continue;
      }

      linePaint.color = backdropTheme.foregroundColor.withOpacity(
        (!userNode) ?
        1.0 - distance / _lineDistanceLimit
        :
        1.0 - distance / (3.0 * _lineDistanceLimit)
      );

      canvas.drawLine(node.position, _paintable.nodes[i].position, linePaint);
    }
  }
}
