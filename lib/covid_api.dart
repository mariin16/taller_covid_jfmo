import 'dart:convert';
import 'package:http/http.dart' as http;
import 'covid_data.dart';

Future<CovidData> fetchCountry(String country) async {
  final uri = Uri.https(
    'disease.sh',
    '/v3/covid-19/countries/${Uri.encodeComponent(country)}',
  );
  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Error del servidor: ${response.statusCode}');
  }
  return CovidData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}