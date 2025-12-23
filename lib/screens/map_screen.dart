// lib/screens/map_screen.dart
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InteractiveViewer(
        minScale: 0.5, // rimpicciolisce fino al 50%
        maxScale: 1.5, // ingrandisce fino al 150%
        constrained: true, // 🔒 evita che l'immagine "scappi"
        panEnabled: true,
        scaleEnabled: true,
        child: Center(
          child: Image.asset(
            'assets/maps/scuola.jpeg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
