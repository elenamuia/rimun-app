import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../services/committee_service.dart';
import '../repositories/committee_repository.dart';
import '../api/models.dart' as api;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  FloorLevel _floor = FloorLevel.ground;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  late final Future<List<_CommitteeMapEntry>> _futureEntries;

  // Your local floor mapping (from CSV, asset file, or hardcoded)
  // Key = committee name (lowercased), Value = floor
  static const _localFloorMap = <String, FloorLevel>{
    'disec': FloorLevel.ground,
    'specpol': FloorLevel.first,
    'ecofin': FloorLevel.second,
    // ... loaded from CSV or asset at build time
  };

  static const _floorLabels = {
    FloorLevel.ground: 'Ground',
    FloorLevel.first: 'First',
    FloorLevel.second: 'Second',
    FloorLevel.third: 'Third',
    FloorLevel.fourth: 'Fourth',
  };

  static const _floorAssets = {
    FloorLevel.ground: 'assets/maps/ground_floor.svg',
    FloorLevel.first: 'assets/maps/first_floor.svg',
    FloorLevel.second: 'assets/maps/second_floor.svg',
    FloorLevel.third: 'assets/maps/third_floor.svg',
    FloorLevel.fourth: 'assets/maps/fourth_floor.svg',
  };
  
  get baseUrl => null;

  @override
  void initState() {
    super.initState();
    _futureEntries = _loadEntries();
  }

  Future<List<_CommitteeMapEntry>> _loadEntries() async {
    // 1. Fetch committees from the API (public, no auth needed)
    final response = await http.get(
      Uri.parse('$baseUrl/api/v2/forums'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load forums: ${response.statusCode}');
    }

    final forums = jsonDecode(response.body) as List;
    final committees = forums
        .expand((f) => (f['committees'] as List?) ?? [])
        .map((c) => api.Committee.fromJson(c as Map<String, dynamic>))
        .toList();

    // 2. Merge with local floor map
    return committees.map((c) {
      final floor = _localFloorMap[c.name.toLowerCase()];
      return _CommitteeMapEntry(committee: c, floor: floor);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_CommitteeMapEntry>>(
      future: _futureEntries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading rooms.\n${snapshot.error}',
                textAlign: TextAlign.center),
          );
        }

        final items = snapshot.data ?? [];
        final options = items.map((e) => e.committee.name).toList();
        final roomToFloor = <String, FloorLevel>{
          for (final e in items)
            if (e.floor != null) e.committee.name: e.floor!,
        };

        final filteredRooms = _getFilteredRooms(options);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.layers),
                      const SizedBox(width: 10),
                      const Text('Floor:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<FloorLevel>(
                          value: _floor,
                          isExpanded: true,
                          items: FloorLevel.values
                              .map((f) => DropdownMenuItem(
                                  value: f, child: Text(_floorLabels[f]!)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _floor = v);
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search committee/room',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    if (filteredRooms.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filteredRooms.map((name) {
                            final hasFloor = roomToFloor.containsKey(name);
                            return ActionChip(
                              label: Text(
                                  name + (hasFloor ? '' : ' (no map)')),
                              onPressed: () =>
                                  _selectRoom(name, roomToFloor),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: SvgPicture.asset(
                      _floorAssets[_floor]!,
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
    if (floor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No floor info available for this committee'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _floor = floor;
      _searchCtrl.clear();
      _query = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$roomName is on ${_floorLabels[floor]} floor'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _CommitteeMapEntry {
  final api.Committee committee;
  final FloorLevel? floor;
  const _CommitteeMapEntry({required this.committee, this.floor});
}
