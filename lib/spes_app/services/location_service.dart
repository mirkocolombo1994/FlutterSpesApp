import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<String?> lookupSupermarketName(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=18&addressdetails=1');
      final response = await http.get(uri, headers: {
        'User-Agent': 'FlutterSpesApp/1.0.0 (mirkocolombo1994@github.com)',
        'Accept-Language': 'it'
      }).timeout(const Duration(seconds: 8));

      String? placeName;

      // Estrai tramite display_name
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['error'] == null && data['display_name'] != null) {
          placeName = data['display_name'].toString().split(',').first.trim();
        }
      }

      // Se non è palesemente un supermercato (es inizia con via/viale/è vuoto o ha numeri), prova Overpass
      if (placeName == null || placeName.toLowerCase().startsWith('via ') || placeName.toLowerCase().startsWith('viale ') || RegExp(r'^[0-9]+$').hasMatch(placeName)) {
        try {
          final overpassQuery = '''
            [out:json];
            (
              node["shop"="supermarket"](around:150, $lat, $lon);
              way["shop"="supermarket"](around:150, $lat, $lon);
              rel["shop"="supermarket"](around:150, $lat, $lon);
              node["shop"="convenience"](around:150, $lat, $lon);
            );
            out tags;
          ''';
          
          final overpassUri = Uri.parse('https://overpass-api.de/api/interpreter');
          final overpassResp = await http.post(overpassUri, body: overpassQuery, headers: {'User-Agent':'FlutterSpesApp/1.0.0'}).timeout(const Duration(seconds: 8));
          
          if (overpassResp.statusCode == 200) {
             final opData = json.decode(overpassResp.body);
             if (opData['elements'] != null && (opData['elements'] as List).isNotEmpty) {
               final elements = opData['elements'] as List;
               for (var el in elements) {
                 if (el['tags'] != null && el['tags']['name'] != null) {
                   placeName = el['tags']['name'];
                   break;
                 }
               }
             }
          }
        } catch (_) {}
      }

      // Se alla fine resta generico, rigettiamo per non inquinare il DB
      if (placeName == null || placeName.isEmpty || placeName.toLowerCase().startsWith('via ') || placeName.toLowerCase().startsWith('viale ') || RegExp(r'^[0-9]+$').hasMatch(placeName)) {
        return null;
      }
      
      return placeName;
    } catch (_) {
      return null;
    }
  }
}
