class Session {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // Workshop, Talk, Keynote, Break, etc.
  final String audience; // Beginner, Intermediate, Advanced, All
  final String speaker;
  final String location;
  final List<String> tags;

  Session({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.audience,
    required this.speaker,
    required this.location,
    this.tags = const [],
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      type: json['type'] as String,
      audience: json['audience'] as String,
      speaker: json['speaker'] as String,
      location: json['location'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'type': type,
      'audience': audience,
      'speaker': speaker,
      'location': location,
      'tags': tags,
    };
  }

  // Times are stored as CDT hours in UTC (i.e. 11:30 AM CDT → T11:30:00Z).
  // Display the UTC hour/minute directly and label it CDT so non-CDT users
  // know the timezone without the app converting to their local time.

  String get dateKey {
    final t = startTime.toUtc();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  String get timeRange {
    final s = startTime.toUtc();
    final e = endTime.toUtc();
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(s)} - ${fmt(e)} CDT';
  }
}
