import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>?> getProductFromApi(String barcode) async {
  final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    // Si producto existe, retorna info
    if (json['product'] != null) return json['product'];
  }
  return null;
}
