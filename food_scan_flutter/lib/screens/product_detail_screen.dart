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

      setState(() {
        product = query.docs.isNotEmpty ? query.docs.first.data() : null;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar producto: $e');
      setState(() {
        product = null;
        loading = false;
      });
    }
  }

  /// 🚦 Calcula color semáforo (OMS aprox)
  Color getTrafficLight(num value, num low, num high) {
    if (value >= high) return Colors.red;
    if (value > low) return Colors.amber;
    return Colors.green;
  }

  /// 📊 Calificación global
  String getGlobalRating() {
    if (product == null) return 'Sin datos';

    int redFlags = 0;
    int yellowFlags = 0;

    final sugar = (product!['azucar'] ?? 0).toDouble();
    final fat = (product!['grasas'] ?? 0).toDouble();
    final salt = (product!['sal'] ?? product!['sodio'] ?? 0).toDouble();

    if (sugar >= 15) redFlags++; else if (sugar > 5) yellowFlags++;
    if (fat   >= 20) redFlags++; else if (fat   > 3) yellowFlags++;
    if (salt  >= 0.6) redFlags++; else if (salt  > 0.12) yellowFlags++;

    if (redFlags >= 2) return '⚠️ Alto en múltiples nutrientes críticos';
    if (redFlags == 1 && yellowFlags >= 1) return '⚠️ Consumir con moderación';
    if (redFlags == 1) return '⚠️ Alto en un nutriente crítico';
    if (yellowFlags >= 2) return 'ℹ️ Niveles moderados de nutrientes';
    if (yellowFlags == 1) return '✓ Mayormente saludable';
    return '✓ Producto nutricionalmente equilibrado';
  }

  /// 🎨 Color del indicador global
  Color getGlobalColor() {
    if (product == null) return Colors.grey;
    final sugar = (product!['azucar'] ?? 0).toDouble();
    final fat   = (product!['grasas'] ?? 0).toDouble();
    final salt  = (product!['sal'] ?? product!['sodio'] ?? 0).toDouble();

    final hasRed    = sugar >= 15 || fat >= 20 || salt >= 0.6;
    final hasYellow = sugar > 5   || fat > 3   || salt > 0.12;

    if (hasRed) return Colors.red;
    if (hasYellow) return Colors.amber;
    return Colors.green;
  }

  /// 📦 Tarjeta nutricional responsiva y accesible en modo oscuro
  Widget nutritionCard(
    String label,
    String value,
    Color accentColor, {
    String? description,
  }) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    // Mezcla un tinte del color con el surface actual para que funcione en dark y light
    final bg = Color.alphaBlend(accentColor.withOpacity(0.12), surface);
    final textColor = theme.colorScheme.onSurface;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor, width: 2),
        ),
        child: Column(
          children: [
            // Semáforo circular
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              'por 100g',
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor.withOpacity(0.7),
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String getNutrientLevel(num value, num low, num high) {
    if (value >= high) return 'Alto';
    if (value > low) return 'Moderado';
    return 'Bajo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
        ),
        backgroundColor: cs.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Analizando información nutricional...',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
        ),
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: cs.error),
                const SizedBox(height: 24),
                Text(
                  'Producto no encontrado',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Código: ${widget.codigo}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
                    )),
                const SizedBox(height: 8),
                Text(
                  'No hay información disponible para este código de barras en nuestra base de datos.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear otro producto'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🔹 URL de imagen robusta (distintos nombres de campo)
    final imageUrl = ((product!['imagen'] ??
                        product!['image'] ??
                        product!['image_url'] ??
                        product!['image_front_url'] ??
                        product!['front_image'] ??
                        '')
                      ).toString();

    // Valores nutricionales
    final sugar    = (product!['azucar'] ?? 0).toDouble();
    final fat      = (product!['grasas'] ?? 0).toDouble();
    final salt     = (product!['sal'] ?? product!['sodio'] ?? 0).toDouble(); // usa SAL si existe
    final calories = (product!['calorias'] ?? 0).round();

    // Ingredientes (texto → lista como fallback)
    final ingredientesText = (product!['ingredientes_text'] as String?)?.trim();
    final ingredientesList = (product!['ingredientes'] as List?)?.cast<String>() ?? const [];
    final ingredientesParaMostrar = (ingredientesText != null && ingredientesText.isNotEmpty)
        ? ingredientesText
        : (ingredientesList.isNotEmpty ? ingredientesList.join(', ') : 'Ingredientes no disponibles');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información Nutricional'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      backgroundColor: cs.surface, // ¡respeta modo oscuro/claro!
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📷 Imagen
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: cs.surfaceVariant,
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? Icon(Icons.fastfood, size: 60, color: cs.onSurfaceVariant)
                    : null,
              ),

              const SizedBox(height: 16),

              // 🏷️ Marca
              Text(
                product!["marca"] ?? 'Marca desconocida',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // 📦 Nombre
              Text(
                product!["nombre"] ?? 'Producto sin nombre',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),

              const SizedBox(height: 20),

              // 🚦 Calificación global
              Card(
                elevation: 3,
                color: cs.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        getGlobalColor().withOpacity(0.18),
                        cs.surface,
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
                                  color: getGlobalColor().withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Calificación Nutricional",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getGlobalRating(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📊 Título tabla
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: Text(
                    'Información Nutricional',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),

              // Fila 1
              Row(
                children: [
                  nutritionCard('Calorías', '$calories kcal', Colors.orange.shade700, description: 'Energía'),
                  nutritionCard('Azúcares', '${sugar.toStringAsFixed(1)}g',
                      getTrafficLight(sugar, 5, 15),
                      description: getNutrientLevel(sugar, 5, 15)),
                ],
              ),

              // Fila 2
              Row(
                children: [
                  nutritionCard('Grasas', '${fat.toStringAsFixed(1)}g',
                      getTrafficLight(fat, 3, 20),
                      description: getNutrientLevel(fat, 3, 20)),
                  nutritionCard('Sal', '${salt.toStringAsFixed(2)}g',
                      getTrafficLight(salt, 0.12, 0.6),
                      description: getNutrientLevel(salt, 0.12, 0.6)),
                ],
              ),

              const SizedBox(height: 24),

              // 🧪 Ingredientes
              Card(
                elevation: 2,
                color: cs.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt, size: 20, color: cs.onSurface),
                          const SizedBox(width: 8),
                          Text('Ingredientes',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ingredientesParaMostrar,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
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
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text('Escanear otro producto'),
                  onPressed: () => Navigator.pushNamed(context, '/scan'),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Valores calculados por cada 100g de producto',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
