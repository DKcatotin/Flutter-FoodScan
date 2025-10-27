import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> testApiDirectly(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Probando conexión a API...'),
          ],
        ),
      ),
    );

    try {
      const testBarcode = '7501055363308';
      // 👇 IMPORTANTE: agrega .json al endpoint
      final url = 'https://world.openfoodfacts.org/api/v2/product/$testBarcode.json';

      if (kDebugMode) {
        print('🧪 PRUEBA DIRECTA DE API');
      }
      print('📍 URL: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response length: ${response.body.length}');

      if (!context.mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final status = json['status'];
        final productName = json['product']?['product_name'] ?? 'Sin nombre';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ API Funciona!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status HTTP: ${response.statusCode}'),
                const SizedBox(height: 8),
                Text('Status API: $status'),
                const SizedBox(height: 8),
                const Text('Producto encontrado:'),
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Error HTTP'),
            content: Text(
              'Status Code: ${response.statusCode}\n\nLa API no respondió correctamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔴 Error de Conexión'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // usa el esquema del tema

    return Scaffold(
      // 👇 no pongas backgroundColor aquí; deja que el tema pinte el fondo
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🔥 sin flecha atrás
        title: const Text('FoodScan'),
        actions: [
          IconButton(
            tooltip: widget.darkMode ? 'Modo claro' : 'Modo oscuro',
            icon: Icon(
              widget.darkMode ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Ícono principal con colores del tema
            Container(
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 48,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'FoodScan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 18),

            // 🔍 Botón de escaneo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'Escanear producto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pushNamed(context, '/scan'),
              ),
            ),
            const SizedBox(height: 14),

            // 🕓 Historial
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Ver historial', style: TextStyle(fontSize: 16)),
                onPressed: () => Navigator.pushNamed(context, '/history'),
              ),
            ),
            const SizedBox(height: 14),

            // 🧪 Test API
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.bug_report),
                label: const Text('🧪 Probar API', style: TextStyle(fontSize: 16)),
                onPressed: () => Navigator.pushNamed(context, '/api-test'),
              ),
            ),
            const SizedBox(height: 22),

            // 📘 Info Card 1
            Card(
              margin: const EdgeInsets.only(bottom: 18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Aprende sobre nutrición',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                          SizedBox(height: 4),
                          Text(
                            'Escanea el código de barras de cualquier producto alimenticio para conocer su información nutricional de manera clara y visual.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🚦 Info Card 2
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, size: 16),
                        SizedBox(width: 2),
                        Icon(Icons.circle, size: 16),
                        SizedBox(width: 2),
                        Icon(Icons.circle, size: 16),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Semáforo nutricional',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                          SizedBox(height: 4),
                          Text(
                            'Identifica fácilmente qué nutrientes están en niveles saludables, moderados o altos con nuestro sistema de colores intuitivo.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
