import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Obtiene producto de OpenFoodFacts y lo convierte al formato de tu app
Future<Map<String, dynamic>?> getProductFromApi(String barcode) async {
  final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode.json';
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔍 INICIANDO CONSULTA A API');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📍 URL: $url');
  print('🔢 Código de barras: $barcode');
  
  try {
    print('⏳ Haciendo petición HTTP...');
    final response = await http.get(Uri.parse(url));
    
    print('📡 Status Code: ${response.statusCode}');
    print('📦 Body Length: ${response.body.length} caracteres');
    
    if (response.statusCode != 200) {
      print('❌ Error HTTP: Status ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      return null;
    }
    
    print('✅ Respuesta HTTP exitosa');
    print('🔄 Parseando JSON...');
    
    final json = jsonDecode(response.body);
    print('✅ JSON parseado correctamente');
    
    // Verificar status de OpenFoodFacts
    print('📊 Status de API: ${json['status']}');
    print('📊 Status verbose: ${json['status_verbose']}');
    
    if (json['status'] != 1) {
      print('⚠️ Producto no encontrado (status != 1)');
      return null;
    }
    
    if (json['product'] == null) {
      print('⚠️ Campo "product" es null');
      return null;
    }
    
    print('✅ Producto encontrado en API');
    final apiProduct = json['product'];
    
    // Debug: Mostrar campos disponibles
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 DATOS CRUDOS DEL PRODUCTO:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Nombre: ${apiProduct['product_name']}');
    print('Marca: ${apiProduct['brands']}');
    print('Imagen: ${apiProduct['image_url']}');
    print('Calorías: ${apiProduct['nutriments']?['energy-kcal_100g']}');
    print('Azúcares: ${apiProduct['nutriments']?['sugars_100g']}');
    print('Grasas: ${apiProduct['nutriments']?['fat_100g']}');
    print('Sal: ${apiProduct['nutriments']?['salt_100g']}');
    print('Ingredientes: ${apiProduct['ingredients_text']}');
    
    // 📦 Mapear datos de OpenFoodFacts a tu estructura
    final productData = {
      'codigo': barcode,
      'nombre': apiProduct['product_name'] ?? 'Producto sin nombre',
      'marca': apiProduct['brands'] ?? 'Marca desconocida',
      'imagen': apiProduct['image_url'] ?? '',
      
      // Nutrientes por 100g
      'calorias': _parseNutrient(apiProduct['nutriments']?['energy-kcal_100g']),
      'azucar': _parseNutrient(apiProduct['nutriments']?['sugars_100g']),
      'grasas': _parseNutrient(apiProduct['nutriments']?['fat_100g']),
      'sodio': _parseNutrient(apiProduct['nutriments']?['salt_100g']),
      'proteinas': _parseNutrient(apiProduct['nutriments']?['proteins_100g']),
      
      // Ingredientes
      'ingredientes': _parseIngredients(apiProduct['ingredients_text']),
      
      // Metadatos
      'fechaConsulta': FieldValue.serverTimestamp(),
      'fuente': 'OpenFoodFacts',
    };
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ DATOS PROCESADOS:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Nombre: ${productData['nombre']}');
    print('Marca: ${productData['marca']}');
    print('Calorías: ${productData['calorias']}');
    print('Azúcar: ${productData['azucar']}g');
    print('Grasas: ${productData['grasas']}g');
    print('Sal: ${productData['sodio']}g');
    print('Ingredientes: ${(productData['ingredientes'] as List).length} items');
    
    // 💾 Guardar en Firestore para futuras consultas
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💾 Guardando en Firestore...');
    await _saveToFirestore(productData);
    print('✅ Guardado exitoso en Firestore');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return productData;
    
  } catch (e, stackTrace) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔴 ERROR FATAL EN API:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Error: $e');
    print('Stack Trace:');
    print(stackTrace);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return null;
  }
}

/// Convierte valores nutricionales a número seguro
num _parseNutrient(dynamic value) {
  if (value == null) {
    print('⚠️ Nutriente null, usando 0');
    return 0;
  }
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value) ?? 0;
    print('🔄 String "$value" convertido a $parsed');
    return parsed;
  }
  print('⚠️ Tipo desconocido: ${value.runtimeType}, usando 0');
  return 0;
}

/// Convierte string de ingredientes a lista
List<String> _parseIngredients(String? ingredientsText) {
  if (ingredientsText == null || ingredientsText.isEmpty) {
    print('⚠️ Sin ingredientes, usando placeholder');
    return ['Ingredientes no disponibles'];
  }
  
  // Separa por comas y limpia espacios
  final ingredients = ingredientsText
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  
  print('✅ ${ingredients.length} ingredientes parseados');
  return ingredients;
}

/// Guarda producto en Firestore
Future<void> _saveToFirestore(Map<String, dynamic> product) async {
  try {
    await FirebaseFirestore.instance
        .collection('productos')
        .doc(product['codigo'])
        .set(product, SetOptions(merge: true));
    
    print('✅ Producto ${product['codigo']} guardado en Firestore');
  } catch (e) {
    print('⚠️ No se pudo guardar en Firestore: $e');
    // No lanzamos error para no bloquear la visualización
  }
}