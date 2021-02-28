import 'package:flutter/material.dart';

import 'package:portfolio_web/main.dart';
export 'src/backdrop/backdrop.dart';

void main() {
  runApp(BackDropDemo());
}

class BackDropDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // showPerformanceOverlay: true,
      home: BackdropAnimation(),
    );
  }
}