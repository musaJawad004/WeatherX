class WeatherModel {
  final String? cityName;
  final double? temperature;
  final String? maincondition;

  WeatherModel({this.cityName, this.temperature, this.maincondition});

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'],
      temperature: (json['main']['temp'] as num?)?.toDouble(),
      maincondition: json['weather'][0]['main'],
    );
  }  
}