import 'package:flutter/material.dart';

import 'src/animation/backdrop/backdrop.dart';

export 'src/animation/backdrop/backdrop.dart';

void main() {
  runApp(BackDropDemo());
}

class BackDropDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // showPerformanceOverlay: true,
      home: Stack(
        children: [BackdropAnimation()],
      ),
    );
  }
}
