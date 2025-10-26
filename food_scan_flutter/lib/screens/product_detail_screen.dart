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
  }

  Color getTrafficLight(num value, num low, num high) {
    if (value >= high) return Colors.red;
    if (value > low && value < high) return Colors.amber;
    return Colors.green;
  }

  Widget nutritionCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color.darken(0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, color: color.darken(0.2))),
            Text('por 100g', style: TextStyle(fontSize: 12, color: color.darken(0.2))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Producto no encontrado', style: TextStyle(fontSize: 18, color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.grey[200],
                  image: product!["imagen"] != null
                      ? DecorationImage(image: NetworkImage(product!["imagen"]), fit: BoxFit.cover)
                      : null,
                ),
                child: product!["imagen"] == null
                    ? Icon(Icons.fastfood, size: 56, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(height: 16),
              Text(product!["marca"] ?? '', style: const TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(product!["nombre"] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: getTrafficLight(product!["azucar"] ?? 0, 5, 15),
                            radius: 7,
                          ),
                          const SizedBox(width: 10),
                          const Text("Calificación nutricional", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Este producto tiene niveles moderados de nutrientes", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  nutritionCard('Calorías', '${product!["calorias"]} kcal', Colors.orange.shade700),
                  nutritionCard('Azúcares', '${product!["azucar"]}g', getTrafficLight(product!["azucar"] ?? 0, 5, 15)),
                ],
              ),
              Row(
                children: [
                  nutritionCard('Grasas', '${product!["grasas"]}g', getTrafficLight(product!["grasas"] ?? 0, 3, 20)),
                  nutritionCard('Sal', '${product!["sodio"] ?? 0}g', getTrafficLight(product!["sodio"] ?? 0, 0.12, 0.6)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Componentes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                (product!["ingredientes"] as List<dynamic>).join(', '),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Escanear otro producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorHelpers on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
