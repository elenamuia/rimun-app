import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum FloorLevel { ground, first, second, third }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  FloorLevel _floor = FloorLevel.ground;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const _floorLabels = {
    FloorLevel.ground: 'Ground',
    FloorLevel.first: 'First',
    FloorLevel.second: 'Second',
    FloorLevel.third: 'Third',
  };

  static const _floorAssets = {
    FloorLevel.ground: 'assets/maps/ground_floor.svg',
    FloorLevel.first: 'assets/maps/first_floor.svg',
    FloorLevel.second: 'assets/maps/second_floor.svg',
    FloorLevel.third: 'assets/maps/third_floor.svg',
  };

  /// ✅ QUI metti tu manualmente i nomi delle aule e a che piano stanno.
  /// Esempi: cambiali con quelli veri.
  final Map<String, FloorLevel> _rooms = {
    'Lost & Found': FloorLevel.ground,
    'Layout Panel': FloorLevel.ground,
    'Luggage Deposit': FloorLevel.ground,
    'Dining Area': FloorLevel.ground,
    'Cafeteria': FloorLevel.ground,

    'GA1': FloorLevel.first,
    'GA2': FloorLevel.first,
    'GA3': FloorLevel.first,
    'GA4': FloorLevel.first,
    'GA5': FloorLevel.first,
    'GA6': FloorLevel.first,

    'HRC': FloorLevel.second,
    'ESCWA': FloorLevel.second,
    'CESCR': FloorLevel.second,
    'CSW': FloorLevel.second,
    'GA2': FloorLevel.second,
    'CSTD': FloorLevel.second,
    'CSocD': FloorLevel.second,
    'CCPCJ': FloorLevel.second,
    'Approval Panel': FloorLevel.second,

    'CW': FloorLevel.third,
    'SC': FloorLevel.third,
    'TC': FloorLevel.third,
    'HSC': FloorLevel.third,
    'AC': FloorLevel.third,
    'CC': FloorLevel.third,
    'FMI': FloorLevel.third,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredRooms {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return _rooms.keys
        .where((name) => name.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  void _selectRoom(String roomName) {
    final floor = _rooms[roomName];
    if (floor == null) return;

    setState(() {
      _floor = floor;
      _searchCtrl.clear();
      _query = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$roomName is on ${_floorLabels[floor]} floor'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = _floorAssets[_floor]!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 🔹 Barra sopra: Piano + Ricerca
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers),
                      const SizedBox(width: 10),
                      const Text(
                        'Floor:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<FloorLevel>(
                          value: _floor,
                          isExpanded: true,
                          items: FloorLevel.values.map((f) {
                            return DropdownMenuItem(
                              value: f,
                              child: Text(_floorLabels[f]!),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _floor = v);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search room',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),

                  // 🔹 Suggerimenti risultati
                  if (_filteredRooms.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _filteredRooms.map((room) {
                          return ActionChip(
                            label: Text(room),
                            onPressed: () => _selectRoom(room),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Mappa con zoom (minScale 0.5 = 50%)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: SvgPicture.asset(
                  asset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
