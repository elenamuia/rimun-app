import 'package:flutter/services.dart' show rootBundle;

enum FloorLevel { ground, first, second, third, fourth }

class CommitteeService {
  Future<CommitteeData> loadCommittees() async {
    final csvString = await rootBundle.loadString('assets/committees.csv');

    final lines = csvString
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CommitteeData(options: [], committeeToFloor: {});
    }

    // header?
    int startIndex = 0;
    if (lines[0].toLowerCase().contains('committee') &&
        lines[0].toLowerCase().contains('floor')) {
      startIndex = 1;
    }

    final Map<String, FloorLevel> map = {};
    final List<String> options = [];

    for (var i = startIndex; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 2) continue;

      final committee = parts[0].trim();
      final floorStr = parts[1].trim().toLowerCase();

      final floor = _parseFloor(floorStr);
      if (committee.isEmpty || floor == null) continue;

      map[committee] = floor;
      options.add(committee);
    }

    options.sort((a, b) => a.compareTo(b));

    return CommitteeData(
      options: options,
      committeeToFloor: map,
    );
  }

  FloorLevel? _parseFloor(String v) {
    switch (v) {
      case 'ground':
        return FloorLevel.ground;
      case 'first':
        return FloorLevel.first;
      case 'second':
        return FloorLevel.second;
      case 'third':
        return FloorLevel.third;
      case 'fourth':
        return FloorLevel.fourth;
      default:
        return null;
    }
  }
}

class CommitteeData {
  final List<String> options;
  final Map<String, FloorLevel> committeeToFloor;

  const CommitteeData({
    required this.options,
    required this.committeeToFloor,
  });
}
