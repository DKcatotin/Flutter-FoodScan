import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// --------- Helpers fuera del main --------

double? toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

double pickNutriment(Map n, List<String> keys, {double fallback = 0}) {
  for (final k in keys) {
    final val = toDouble(n[k]);
    if (val != null) return val;
  }
  return fallback;
}

/// Convierte valores nutricionales simples a número seguro (fallback)
num parseNutrient(dynamic value) {
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

/// Convierte string de ingredientes a lista (compatibilidad)
List<String> parseIngredients(String? ingredientsText) {
  if (ingredientsText == null || ingredientsText.isEmpty) {
    print('⚠️ Sin ingredientes (texto), devolviendo placeholder');
    return ['Ingredientes no disponibles'];
  }
  final ingredients = ingredientsText
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  print('✅ ${ingredients.length} ingredientes parseados desde texto');
  return ingredients;
}

/// Guarda producto en Firestore
Future<void> saveToFirestore(Map<String, dynamic> product) async {
  try {
    await FirebaseFirestore.instance
        .collection('productos')
        .doc(product['codigo'])
        .set(product, SetOptions(merge: true));
    print('✅ Producto ${product['codigo']} guardado en Firestore');
  } catch (e) {
    print('⚠️ No se pudo guardar en Firestore: $e');
  }
}

// --------------- Main fetch function ---------------

/// Obtiene producto de OpenFoodFacts, normaliza campos y guarda en Firestore
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

    final body = jsonDecode(response.body);
    print('✅ JSON parseado correctamente');

    print('📊 Status de API: ${body['status']}');
    print('📊 Status verbose: ${body['status_verbose']}');

    if (body['status'] != 1 || body['product'] == null) {
      print('⚠️ Producto no encontrado o sin campo "product"');
      return null;
    }

    final p = body['product'] as Map<String, dynamic>;

    // ---------- Imagen ----------
    final image =
        p['image_front_url'] ??
        p['image_url'] ??
        p['selected_images']?['front']?['display']?['es'] ??
        p['selected_images']?['front']?['display']?['en'];

    // ---------- Ingredientes ----------
    final ingredientsText =
        p['ingredients_text_es'] ??
        p['ingredients_text'] ??
        p['ingredients_text_en'];

    final ingredientsArray = (p['ingredients'] is List)
        ? (p['ingredients'] as List)
            .map((e) => (e is Map && e['text'] != null)
                ? e['text'].toString()
                : (e is Map && e['id'] != null)
                    ? e['id'].toString()
                    : null)
            .whereType<String>()
            .toList()
        : <String>[];

    final ingredientesTextNormalizado =
        (ingredientsText is String && ingredientsText.trim().isNotEmpty)
            ? ingredientsText
            : (ingredientsArray.isNotEmpty ? ingredientsArray.join(', ') : '');

    // ---------- Nutrimentos ----------
    final nutr = (p['nutriments'] as Map?) ?? {};

    // Calorías: intentar kcal; si no, convertir desde kJ
    double calories = pickNutriment(nutr, ['energy-kcal_100g', 'energy-kcal']);
    if (calories == 0) {
      final kJ = pickNutriment(nutr, ['energy_100g', 'energy']);
      if (kJ > 0) calories = kJ / 4.184; // kJ -> kcal
    }
    calories = double.parse(calories.toStringAsFixed(0));

    // Azúcar, grasa, proteínas
    final sugars = pickNutriment(nutr, ['sugars_100g', 'sugars']); // g/100g
    final fat = pickNutriment(nutr, ['fat_100g', 'fat']); // g/100g
    final proteins =
        pickNutriment(nutr, ['proteins_100g', 'proteins']); // g/100g

    // Sal/Sodio
    double salt = pickNutriment(nutr, ['salt_100g', 'salt']); // g/100g
    double sodium = pickNutriment(nutr, ['sodium_100g', 'sodium']); // g/100g
    // Si sodio viene evidentemente en mg (valor "grande"), convertir a g
    if (sodium > 10) sodium = sodium / 1000;
    if (salt == 0 && sodium > 0) salt = sodium * 2.5;

    // ---------- Extras útiles ----------
    final nutriScore = p['nutriscore_grade']; // a..e
    final novaGroup = p['nova_group']; // 1..4
    final allergens = (p['allergens_tags'] as List?) ?? [];
    final additives = (p['additives_tags'] as List?) ?? [];
    final labels = (p['labels_tags'] as List?) ?? [];

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 DATOS CRUDOS DEL PRODUCTO (resumen):');
    print('Nombre: ${p['product_name']}');
    print('Marca: ${p['brands']}');
    print('Imagen: $image');
    print('Calorías(kcal/100g): $calories');
    print('Azúcares(g/100g): $sugars');
    print('Grasas(g/100g): $fat');
    print('Sal(g/100g): $salt  | Sodio(g/100g): $sodium');
    print('Ingredientes(TXT): ${ingredientesTextNormalizado.isNotEmpty}');
    print('Ingredientes(ARR): ${ingredientsArray.length} items');

    // ---------- Mapeo al modelo de tu app ----------
    final productData = {
      'codigo': barcode,
      'nombre': p['product_name_es'] ?? p['product_name'] ?? 'Producto sin nombre',
      'marca': p['brands'] ?? 'Marca desconocida',
      'imagen': image ?? '',

      // Nutrientes por 100g
      'calorias': calories,
      'azucar': sugars,
      'grasas': fat,
      'sodio': sodium,
      'sal': salt,
      'proteinas': proteins,

      // Ingredientes
      'ingredientes_text': ingredientesTextNormalizado,
      'ingredientes': ingredientsArray,

      // Extras
      'nutriscore': nutriScore,
      'nova_group': novaGroup,
      'alergenos': allergens,
      'aditivos': additives,
      'etiquetas': labels,

      // Metadatos
      'fechaConsulta': FieldValue.serverTimestamp(),
      'fuente': 'OpenFoodFacts',
      'updated_at': DateTime.now().toIso8601String(),
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ DATOS PROCESADOS:');
    print('Nombre: ${productData['nombre']}');
    print('Marca: ${productData['marca']}');
    print('Calorías: ${productData['calorias']}');
    print('Azúcar: ${productData['azucar']} g');
    print('Grasas: ${productData['grasas']} g');
    print('Sal: ${productData['sal']} g | Sodio: ${productData['sodio']} g');
    print('Ingredientes TXT vacío?: ${(productData['ingredientes_text'] as String).isEmpty}');
    print('Ingredientes ARR: ${(productData['ingredientes'] as List).length} items');
    print('NutriScore: ${productData['nutriscore']} | NOVA: ${productData['nova_group']}');

    // Guardar/actualizar en Firestore
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💾 Guardando en Firestore...');
    await saveToFirestore(productData);
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
