import 'package:flutter/material.dart';
import 'package:portfolio_web/backdrop.dart';

void main() {
  runApp(BackDropDemo());
}

class BackDropDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackdropAnimation();
  }
}