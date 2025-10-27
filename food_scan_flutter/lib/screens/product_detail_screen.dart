import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String codigo;
  const ProductDetailScreen({required this.codigo, super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('productos')
          .where('codigo', isEqualTo: widget.codigo)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          product = query.docs.first.data();
          loading = false;
        });
      } else {
        setState(() {
          product = null;
          loading = false;
        });
      }
    } catch (e) {
      print('Error al cargar producto: $e');
      setState(() {
        product = null;
        loading = false;
      });
    }
  }

  /// 🚦 Calcula el color del semáforo según límites nutricionales (OMS)
  Color getTrafficLight(num value, num low, num high) {
    if (value >= high) return Colors.red; // Alto
    if (value > low) return Colors.amber; // Moderado
    return Colors.green; // Bajo/Saludable
  }

  /// 📊 Calcula la calificación GLOBAL del producto
  String getGlobalRating() {
    if (product == null) return 'Sin datos';

    int redFlags = 0;
    int yellowFlags = 0;

    // Evaluar azúcar (límites: bajo < 5g, alto >= 15g)
    final sugar = (product!['azucar'] ?? 0).toDouble();
    if (sugar >= 15) {
      redFlags++;
    } else if (sugar > 5) {
      yellowFlags++;
    }

    // Evaluar grasas totales (límites: bajo < 3g, alto >= 20g)
    final fat = (product!['grasas'] ?? 0).toDouble();
    if (fat >= 20) {
      redFlags++;
    } else if (fat > 3) {
      yellowFlags++;
    }

    // Evaluar sal/sodio (límites: bajo < 0.12g, alto >= 0.6g)
    final salt = (product!['sodio'] ?? 0).toDouble();
    if (salt >= 0.6) {
      redFlags++;
    } else if (salt > 0.12) {
      yellowFlags++;
    }

    // Determinar calificación global
    if (redFlags >= 2) {
      return '⚠️ Alto en múltiples nutrientes críticos';
    }
    if (redFlags == 1 && yellowFlags >= 1) {
      return '⚠️ Consumir con moderación';
    }
    if (redFlags == 1) {
      return '⚠️ Alto en un nutriente crítico';
    }
    if (yellowFlags >= 2) {
      return 'ℹ️ Niveles moderados de nutrientes';
    }
    if (yellowFlags == 1) {
      return '✓ Mayormente saludable';
    }
    return '✓ Producto nutricionalmente equilibrado';
  }

  /// 🎨 Color del indicador global
  Color getGlobalColor() {
    if (product == null) return Colors.grey;

    int redFlags = 0;
    int yellowFlags = 0;

    final sugar = (product!['azucar'] ?? 0).toDouble();
    final fat = (product!['grasas'] ?? 0).toDouble();
    final salt = (product!['sodio'] ?? 0).toDouble();

    if (sugar >= 15 || fat >= 20 || salt >= 0.6) redFlags++;
    if (sugar > 5 || fat > 3 || salt > 0.12) yellowFlags++;

    if (redFlags > 0) return Colors.red;
    if (yellowFlags > 0) return Colors.amber;
    return Colors.green;
  }

  /// 📦 Widget de tarjeta nutricional individual
  Widget nutritionCard(String label, String value, Color color, {String? description}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            // Semáforo circular
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.darken(0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.darken(0.2),
              ),
            ),
            Text(
              'por 100g',
              style: TextStyle(
                fontSize: 11,
                color: color.darken(0.2),
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: color.darken(0.1),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📊 Obtiene descripción del nivel nutricional
  String getNutrientLevel(num value, num low, num high) {
    if (value >= high) return 'Alto';
    if (value > low) return 'Moderado';
    return 'Bajo';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Analizando información nutricional...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Producto no encontrado',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Código: ${widget.codigo}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No hay información disponible para este código de barras en nuestra base de datos.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text(
                    'Escanear otro producto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Extraer valores nutricionales
    final sugar = (product!['azucar'] ?? 0).toDouble();
    final fat = (product!['grasas'] ?? 0).toDouble();
    final salt = (product!['sodio'] ?? 0).toDouble();
    final calories = product!['calorias'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información Nutricional'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F9FB),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📷 Imagen del producto
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: product!["imagen"] != null &&
                          product!["imagen"].toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product!["imagen"]),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product!["imagen"] == null ||
                        product!["imagen"].toString().isEmpty
                    ? Icon(Icons.fastfood, size: 60, color: Colors.grey[400])
                    : null,
              ),

              const SizedBox(height: 16),

              // 🏷️ Marca
              Text(
                product!["marca"] ?? 'Marca desconocida',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // 📦 Nombre del producto
              Text(
                product!["nombre"] ?? 'Producto sin nombre',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 🚦 SEMÁFORO NUTRICIONAL GLOBAL
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        getGlobalColor().withValues(alpha: 0.1),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: getGlobalColor(),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      getGlobalColor().withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Calificación Nutricional",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getGlobalRating(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📊 TABLA NUTRICIONAL
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 8),
                  child: Text(
                    'Información Nutricional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // Primera fila: Calorías y Azúcares
              Row(
                children: [
                  nutritionCard(
                    'Calorías',
                    '$calories kcal',
                    Colors.orange.shade700,
                    description: 'Energía',
                  ),
                  nutritionCard(
                    'Azúcares',
                    '${sugar.toStringAsFixed(1)}g',
                    getTrafficLight(sugar, 5, 15),
                    description: getNutrientLevel(sugar, 5, 15),
                  ),
                ],
              ),

              // Segunda fila: Grasas y Sal
              Row(
                children: [
                  nutritionCard(
                    'Grasas',
                    '${fat.toStringAsFixed(1)}g',
                    getTrafficLight(fat, 3, 20),
                    description: getNutrientLevel(fat, 3, 20),
                  ),
                  nutritionCard(
                    'Sal',
                    '${salt.toStringAsFixed(2)}g',
                    getTrafficLight(salt, 0.12, 0.6),
                    description: getNutrientLevel(salt, 0.12, 0.6),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 🧪 INGREDIENTES
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.list_alt, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Ingredientes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (product!["ingredientes"] as List<dynamic>).join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔄 Botón volver
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    'Escanear otro producto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 12),

              // ℹ️ Nota informativa
              Text(
                'Valores calculados por cada 100g de producto',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 Extensión para oscurecer colores
extension ColorHelpers on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}