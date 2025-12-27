// lib/screens/map_screen.dart
import 'package:flutter/material.dart';

class RoomInfo {
  final String name;
  final int floor; // 1, 2, 3
  const RoomInfo(this.name, this.floor);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SearchController _searchController = SearchController();

  // Sample dataset. Replace/extend with your actual rooms.
  final List<RoomInfo> _rooms = const [
    RoomInfo('A101', 1),
    RoomInfo('A102', 1),
    RoomInfo('A201', 2),
    RoomInfo('A202', 2),
    RoomInfo('Auditorium', 1),
    RoomInfo('Segreteria', 1),
    RoomInfo('B301', 3),
    RoomInfo('B302', 3),
  ];

  int _selectedFloor = 1;
  RoomInfo? _selectedRoom;

  final Map<int, String> _floorImages = const {
    1: 'assets/maps/scuola.jpeg',
    2: 'assets/maps/scuola.jpeg',
    3: 'assets/maps/scuola.jpeg',
  };

  List<String> get _roomNames => _rooms.map((r) => r.name).toList();

  void _onRoomSelected(String query) {
    final match = _rooms.firstWhere(
      (r) => r.name.toLowerCase() == query.toLowerCase(),
      orElse: () => RoomInfo(query, _selectedFloor),
    );
    setState(() {
      _selectedRoom = match;
      _selectedFloor = match.floor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchAnchor.bar(
            barElevation: const MaterialStatePropertyAll(0),
            suggestionsBuilder: (context, controller) {
              final query = controller.text.toLowerCase();
              final results =
                  _roomNames
                      .where((name) => name.toLowerCase().contains(query))
                      .toList()
                    ..sort();
              return results.isEmpty
                  ? [
                      ListTile(
                        title: Text('No results for "${controller.text}"'),
                        leading: const Icon(Icons.search_off),
                        onTap: () {},
                      ),
                    ]
                  : results.map((name) {
                      return ListTile(
                        title: Text(name),
                        leading: const Icon(Icons.meeting_room),
                        onTap: () {
                          _searchController.text = name;
                          _onRoomSelected(name);
                          controller.closeView(name);
                        },
                      );
                    }).toList();
            },
            viewLeading: const Icon(Icons.search),
            barHintText: 'Search room (e.g. A101)',
            searchController: _searchController,
            onSubmitted: (value) => _onRoomSelected(value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedRoom == null
                      ? 'Select a room to see its floor'
                      : '${_selectedRoom!.name} — Floor ${_selectedRoom!.floor}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              DropdownButton<int>(
                value: _selectedFloor,
                items: const [1, 2, 3]
                    .map(
                      (f) =>
                          DropdownMenuItem(value: f, child: Text('Floor $f')),
                    )
                    .toList(),
                onChanged: (f) {
                  if (f == null) return;
                  setState(() => _selectedFloor = f);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 1.5,
              constrained: true,
              panEnabled: true,
              scaleEnabled: true,
              child: Center(
                child: Image.asset(
                  _floorImages[_selectedFloor]!,
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
