class Observation {
  final int clientId;
  final String clientName;
  final String responsible;
  final DateTime date;
  final bool visited;
  final String? observation;

  Observation({
    required this.clientId,
    required this.clientName,
    required this.responsible,
    required this.date,
    required this.visited,
    this.observation,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      clientId: json['clientId'],
      clientName: json['clientName'],
      responsible: json['responsible'],
      date: DateTime.parse(json['date']),
      visited:
          json['visited'] is bool ? json['visited'] : json['visited'] == 1,
      observation: json['observation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'responsible': responsible,
      'date': date.toIso8601String(),
      'visited': visited,
      'observation': observation,
    };
  }
}
