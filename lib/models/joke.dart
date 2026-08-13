class Joke {
  final int? id;
  final String title;
  final String setup;
  final String punchline;
  final String type;
  final String status;
  final String tags;
  final String time;
  final String notes;
  final int inSetlist;
  final int setlistOrder;

  Joke({
    this.id,
    required this.title,
    required this.setup,
    required this.punchline,
    required this.type,
    required this.status,
    required this.tags,
    required this.time,
    required this.notes,
    this.inSetlist = 0,
    this.setlistOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'setup': setup,
      'punchline': punchline,
      'type': type,
      'status': status,
      'tags': tags,
      'time': time,
      'notes': notes,
      'inSetlist': inSetlist,
      'setlistOrder': setlistOrder,
    };
  }

  factory Joke.fromMap(Map<String, dynamic> map) {
    return Joke(
      id: map['id'] as int?,
      title: map['title'] as String,
      setup: map['setup'] as String,
      punchline: map['punchline'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      tags: map['tags'] as String,
      time: map['time'] as String,
      notes: map['notes'] as String,
      inSetlist: map['inSetlist'] as int? ?? 0,
      setlistOrder: map['setlistOrder'] as int? ?? 0,
    );
  }

  Joke copyWith({
    int? id,
    String? title,
    String? setup,
    String? punchline,
    String? type,
    String? status,
    String? tags,
    String? time,
    String? notes,
    int? inSetlist,
    int? setlistOrder,
  }) {
    return Joke(
      id: id ?? this.id,
      title: title ?? this.title,
      setup: setup ?? this.setup,
      punchline: punchline ?? this.punchline,
      type: type ?? this.type,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      inSetlist: inSetlist ?? this.inSetlist,
      setlistOrder: setlistOrder ?? this.setlistOrder,
    );
  }
}
