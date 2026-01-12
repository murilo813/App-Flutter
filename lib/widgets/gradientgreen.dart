import 'package:flutter/material.dart';

class GradientGreen {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF049271)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF16A34A), Color(0xFF049271)],
  );
}
