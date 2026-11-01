class City {
  final String name;
  final String country;
  // область / регион, может не быть
  final String region;
  final double latitude;
  final double longitude;

  const City({
    required this.name,
    required this.country,
    this.region = '',
    required this.latitude,
    required this.longitude,
  });

  // "Москва, Россия"
  String get title => country.isEmpty ? name : '$name, $country';

  // один элемент из results ответа геокодера Open-Meteo
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      country: (json['country'] as String?) ?? '',
      region: (json['admin1'] as String?) ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  // для кэша пишем те же ключи, что в ответе API, чтобы читать одним fromJson
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'admin1': region,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
