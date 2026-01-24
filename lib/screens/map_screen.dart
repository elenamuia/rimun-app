import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/committee_service.dart'; 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  FloorLevel _floor = FloorLevel.ground;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final _committeeService = CommitteeService();
  late final Future<CommitteeData> _futureCommittees;

  static const _floorLabels = {
    FloorLevel.ground: 'Ground',
    FloorLevel.first: 'First',
    FloorLevel.second: 'Second',
    FloorLevel.third: 'Third',
    FloorLevel.fourth: 'Fourth'
  };

  static const _floorAssets = {
    FloorLevel.ground: 'assets/maps/ground_floor.svg',
    FloorLevel.first: 'assets/maps/first_floor.svg',
    FloorLevel.second: 'assets/maps/second_floor.svg',
    FloorLevel.third: 'assets/maps/third_floor.svg',
    FloorLevel.fourth: 'assets/maps/fourth_floor.svg'
  };

  @override
  void initState() {
    super.initState();
    _futureCommittees = _committeeService.loadCommittees();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommitteeData>(
      future: _futureCommittees,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rooms.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final data = snapshot.data ??
            const CommitteeData(options: [], committeeToFloor: {});
        final options = data.options; // lista nomi (aule/committee)
        final roomToFloor = data.committeeToFloor; // nome -> piano

        final asset = _floorAssets[_floor]!;

        final filteredRooms = _getFilteredRooms(options);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔹 Barra sopra: Piano + Ricerca
              Card(
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      if (filteredRooms.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filteredRooms.map((roomName) {
                              return ActionChip(
                                label: Text(roomName),
                                onPressed: () =>
                                    _selectRoom(roomName, roomToFloor),
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

              // 🔹 Mappa con zoom
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
      },
    );
  }

  List<String> _getFilteredRooms(List<String> options) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return options
        .where((name) => name.toLowerCase().contains(q))
        .take(10)
        .toList();
  }

  void _selectRoom(String roomName, Map<String, FloorLevel> roomToFloor) {
    final floor = roomToFloor[roomName];
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
}
