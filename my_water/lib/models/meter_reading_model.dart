class MeterReadingModel {
  final String id;
  final String userId;
  final double reading;
  final double previousReading;
  final double unitsConsumed;
  final DateTime readingDate;
  final int month;
  final int year;
  final String? notes;
  final String? recordedByName;

  const MeterReadingModel({
    required this.id,
    required this.userId,
    required this.reading,
    required this.previousReading,
    required this.unitsConsumed,
    required this.readingDate,
    required this.month,
    required this.year,
    this.notes,
    this.recordedByName,
  });

  factory MeterReadingModel.fromJson(Map<String, dynamic> json) {
    return MeterReadingModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : json['userId'] ?? '',
      reading: (json['reading'] ?? 0).toDouble(),
      previousReading: (json['previousReading'] ?? 0).toDouble(),
      unitsConsumed: (json['unitsConsumed'] ?? 0).toDouble(),
      readingDate: DateTime.tryParse(json['readingDate'] ?? '') ?? DateTime.now(),
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      notes: json['notes'],
      recordedByName: json['recordedBy'] is Map ? json['recordedBy']['name'] : null,
    );
  }
}
