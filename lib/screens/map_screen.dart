// lib/screens/map_screen.dart
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: Image.asset('assets/maps/scuola.png'),
        ),
      ),
    );
  }
}
