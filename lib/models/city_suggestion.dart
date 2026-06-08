class CitySuggestion {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  CitySuggestion({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
    this.state,
  });

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name'] as String,
      country: json['country'] as String,
      state: json['state'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  String get label {
    if (state != null && state!.isNotEmpty) {
      return '$name, $state, $country';
    }
    return '$name, $country';
  }
}
