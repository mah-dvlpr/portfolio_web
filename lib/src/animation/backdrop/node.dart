import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'theme.dart' as backdropTheme;

class Node {
  static final random = Random();
  final nodeBrush = Paint()..color = Colors.white;
  DateTime dateTime;

  /// Current position on canvas.
  Offset position;

  /// Velocity (+/-) in terms of x/y coordinates of current position on canvas.
  static const double velocityMax = 1.0;
  Offset velocity;

  /// A Node grows...
  static const radiusNumberOfIncrements = 32;
  static const double radiusMin = 1.0;
  static const double radiusMax = 4.0;
  double radiusCurrent;
  double radiusTarget;

  /// Currently purely based on [radiusCurrent].
  double mass;

  /// [radiusMax] larger than the class static [radiusMax], will not be honored.
  Node(this.position, this.velocity, double radiusMax) {
    dateTime = DateTime.now();
    radiusMax = min(Node.radiusMax, radiusMax);
    this.radiusTarget =
        random.nextDouble() * (radiusMax - radiusMin) + radiusMin;
    this.radiusCurrent = radiusMin;
    this.mass = this.radiusCurrent;
  }

  static Node getRandomNode(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var position = Offset(
        random.nextDouble() * size.width, random.nextDouble() * size.height);

    // Apply velocity/force in random direction.
    // Pythagorean theorem to get missing cathetus, and apply proper velocity.
    // Note: Realized that this is not really necessary, but if you want to have
    // "correct" values, even for diagonal movement, this is the way to do it.
    var c = random.nextDouble() * velocityMax;
    var a = random.nextDouble() * c;
    var b = sqrt(pow(c, 2) - pow(a, 2));
    a = random.nextBool() ? -a : a;
    b = random.nextBool() ? -b : b;
    var velocity = Offset(a, b);

    return Node(position, velocity, radiusMax);
  }

  void draw(Canvas canvas, Size canvasSize) {
    // Update time - Only render when wanted
    if (DateTime.now().difference(dateTime).inMilliseconds >
            backdropTheme.tickMilliTime30fps &&
        radiusCurrent < radiusTarget) {
      dateTime = DateTime.now();
      radiusCurrent +=
          min(radiusTarget / radiusNumberOfIncrements, radiusTarget);
      mass = radiusCurrent;
    }

    canvas.drawCircle(position, radiusCurrent, nodeBrush);
  }
}

/// Utility class for handling physics of supplied nodes.
// TODO: Might be better to have  this as a kind of singleton to call it a
// delegate?
abstract class NodeEngine {
  static DateTime dateTime = DateTime.now();

  static updateNodes(List<Node> nodes, BuildContext context) {
    // Update time - Only render when wanted
    if (DateTime.now().difference(dateTime).inMilliseconds <
        backdropTheme.tickMilliTime60fps) {
      return;
    }
    dateTime = DateTime.now();

    // Update nodes
    // For current node, update and apply force for every other node
    for (int i = 0; i < nodes.length - 1; ++i) {
      for (int j = i + 1; j < nodes.length; ++j) {
        if (_areNodesTouching(nodes[i], nodes[j])) {
          _combineNodes(nodes, i, j, context);
          break;
        } else {
          _addMutualForce(nodes[i], nodes[j]);
        }
      }

      if (nodes[i] == null) {
        continue;
      }

      var size = MediaQuery.of(context).size;
      nodes[i].position += nodes[i].velocity;
      if (nodes[i].position.dx < 0 ||
          nodes[i].position.dx > size.width ||
          nodes[i].position.dy < 0 ||
          nodes[i].position.dy > size.height) {
        nodes[i] = null;
      }
    }
  }

  static bool _areNodesTouching(Node a, Node b) {
    return (a.position - b.position).distanceSquared <
        pow(a.radiusCurrent + b.radiusCurrent, 2);
  }

  static void _combineNodes(
      List<Node> nodes, int a, int b, BuildContext context) {
    nodes[b].radiusTarget = max(nodes[a].radiusTarget, nodes[b].radiusTarget);
    nodes[b].velocity = (nodes[a].velocity *
            nodes[a].mass /
            (nodes[a].mass + nodes[b].mass)) +
        (nodes[b].velocity * nodes[b].mass / (nodes[a].mass + nodes[a].mass));
    nodes[b].mass = max(nodes[a].mass, nodes[b].mass);
    nodes[a] = null;
  }

  // TODO: Fix
  static void _addMutualForce(Node a, Node b) {
    // Determine magnitude of attraction (some pseudo science here)
    var attraction =
        3 * a.mass * b.mass / (a.position - b.position).distanceSquared;

    // Determine direction (based on the perspective of node 'a')
    var attractionX =
        (a.position.dx < b.position.dx) ? attraction : -attraction;
    var attractionY =
        (a.position.dy < b.position.dy) ? attraction : -attraction;

    // Apply attraction to each node
    var additiveForce = Offset(attractionX, attractionY);
    a.velocity += additiveForce;
    b.velocity += -additiveForce; // Equal, but opposite direction
  }
}
