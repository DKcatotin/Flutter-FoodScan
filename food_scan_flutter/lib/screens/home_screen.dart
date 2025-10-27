import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
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
      final url = 'https://world.openfoodfacts.org/api/v2/product/$testBarcode';
      
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
        
        print('✅ Status: $status');
        print('📦 Producto: $productName');
        
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
                const SizedBox(height: 12),
                const Text(
                  '🎉 La API está funcionando correctamente!',
                  style: TextStyle(color: Colors.green),
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
      print('🔴 ERROR: $e');
      
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

class _HomeScreenState extends State<HomeScreen> {
  bool darkMode = false;

  ThemeData get theme => darkMode
      ? ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF232326),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF232326)),
          primaryColor: Colors.white,
        )
      : ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color(0xFFF9F9FB),
          cardColor: Colors.white,
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          primaryColor: Colors.black,
        );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: darkMode ? Colors.black : const Color(0xFFF9F9FB),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: darkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.person,
                color: darkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
            Switch(
              value: darkMode,
              onChanged: (v) => setState(() => darkMode = v),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: darkMode ? Colors.grey[900] : Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'FoodScan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 18),

              // 🔍 Botón de escaneo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text(
                    'Escanear producto',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                  label: const Text(
                    'Ver historial',
                    style: TextStyle(fontSize: 16),
                  ),
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
                    side: const BorderSide(color: Colors.blue),
                  ),
                  icon: const Icon(Icons.bug_report, color: Colors.blue),
                  label: const Text(
                    '🧪 Probar API',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
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
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aprende sobre nutrición',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    darkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Escanea el código de barras de cualquier producto alimenticio para conocer su información nutricional de manera clara y visual.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
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
                      Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.green, size: 16),
                          SizedBox(width: 2),
                          Icon(Icons.circle, color: Colors.orange, size: 16),
                          SizedBox(width: 2),
                          Icon(Icons.circle, color: Colors.red, size: 16),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semáforo nutricional',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    darkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Identifica fácilmente qué nutrientes están en niveles saludables, moderados o altos con nuestro sistema de colores intuitivo.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
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
      ),
    );
  }
}

