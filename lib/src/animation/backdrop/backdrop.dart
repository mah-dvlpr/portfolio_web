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
  BuildContext _context;

  /// The density (number of nodes) per window area.
  /// Per (x * x) pixels we want z nodes.
  static const double _nodeDensity = 20 / (200 * 200);
  static const int _nodesMax = 256;
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
    _context = context;
    var size = MediaQuery.of(_context).size;

    return GestureDetector(
      onPanStart: (details) => _addUserNode(details.localPosition),
      onPanUpdate: (details) => _addUserNode(details.localPosition),
      onPanEnd: (_) => _addUserNodeToList(),
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
    NodeEngine.updateNodes(_paintable.nodes, _context);
    _regulateNodeAmount(_paintable.nodes);
    _streamController.add(_paintable);
  }

  void _regulateNodeAmount(List<Node> nodes) {
    // Determine suitable max amount of nodes depending on window size.
    var size = MediaQuery.of(_context).size;
    var nodesMax = (size.width * size.height * _nodeDensity).toInt();
    nodesMax = min(nodesMax, _nodesMax);

    // Either add nodes if node density is not reached, 
    // or remove nodes if we have too many.
    int i;
    for (i = 0; i < nodesMax; ++i) {
      if (nodes.length < nodesMax) {
        // Expand list and add new node.
        nodes.add(Node.getRandomNode(_context));
      } else if (i < nodes.length && nodes[i] == null) {
        // Re-add a node to a nullified position in the list.
        nodes[i] = Node.getRandomNode(_context);
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

    // For each node
    for (int i = 0; i < _paintable.nodes.length; ++i) {
      _drawLinesToAllOtherNodes(canvas, _paintable.nodes[i], i + 1);
      _paintable.nodes[i].draw(canvas, size);
    }

    // Extra for user input
    if (_paintable.userNode != null) {
      _drawLinesToAllOtherNodes(canvas, _paintable.userNode, 0);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate != this;
  }

  void _drawLinesToAllOtherNodes(Canvas canvas, Node node, int indexStart) {
    var linePaint = Paint();
    for (int i = indexStart; i < _paintable.nodes.length; ++i) {
      var distance = (node.position-_paintable.nodes[i].position).distance;
      linePaint.color = Color.fromRGBO(
        backdropTheme.foregroundColor.red,
        backdropTheme.foregroundColor.green,
        backdropTheme.foregroundColor.blue,
        (distance < _lineDistanceLimit) ? 1.0 - distance / _lineDistanceLimit : 0);

      canvas.drawLine(node.position, _paintable.nodes[i].position, linePaint);
    }
  }
}
