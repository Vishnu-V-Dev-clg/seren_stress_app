class StressSession {
  final String id;
  final double averageStress;
  final List<double> rawValues;
  final DateTime timestamp;

  StressSession({
    required this.id,
    required this.averageStress,
    required this.rawValues,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'averageStress': averageStress,
    'rawValues': rawValues,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StressSession.fromMap(String id, Map<String, dynamic> map) {
    return StressSession(
      id: id,
      averageStress: (map['averageStress'] as num).toDouble(),
      rawValues: (map['rawValues'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
