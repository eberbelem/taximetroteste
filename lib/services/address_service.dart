import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class AddressService {
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/search';

  Future<List<AddressSuggestion>> buscarEndereco({
    required String query,
    double? lat,
    double? lon,
    int limit = 5,
  }) async {
    if (query.trim().length < 3) return [];

    final params = {
      'q': query,
      'format': 'json',
      'addressdetails': '0',
      'limit': limit.toString(),
      'accept-language': 'pt-BR',
    };

    if (lat != null && lon != null) {
      params['viewbox'] =
          '${lon - 0.05},${lat - 0.05},${lon + 0.05},${lat + 0.05}';
      params['bounded'] = '1';
    }

    final uri = Uri.parse(_nominatimUrl).replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'TaximetroDigital/1.0'},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      return data.map((item) {
        return AddressSuggestion(
          displayName: item['display_name'] as String? ?? '',
          latitude: double.parse(item['lat'] as String),
          longitude: double.parse(item['lon'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
