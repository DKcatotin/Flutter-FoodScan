//import 'dart:convert';
//import 'package:flutter/foundation.dart';
//import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// --- Esta clase debe ir FUERA de HomeScreen ---
class _ScannerIconPainter extends CustomPainter {
  final Color color;
  final double thickness;
  _ScannerIconPainter({required this.color, required this.thickness});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double pad = size.width * 0.20;
    double len = size.width * 0.22;

    // Esquina superior izquierda
    canvas.drawLine(Offset(pad, pad), Offset(pad + len, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + len), paint);
    // Esquina superior derecha
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - len, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + len), paint);
    // Esquina inferior izquierda
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + len, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad, size.height - pad - len), paint);
    // Esquina inferior derecha
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --------- HomeScreen ---------
class HomeScreen extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('FoodScan'),
        actions: [
          IconButton(
            tooltip: darkMode ? 'Modo claro' : 'Modo oscuro',
            icon: Icon(
              darkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: darkMode ? Colors.yellow.shade600 : Colors.black87,
            ),
            onPressed: onToggleTheme,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Ícono personalizado estilo scanner cuadrado
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Color(0xFF0C1024), // O Color(0xFF0C1024) si quieres forzar el color
                borderRadius: BorderRadius.circular(22),
              ),
              child: CustomPaint(
                painter: _ScannerIconPainter(color: Colors.white, thickness: 5),
                child: Container(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'FoodScan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 22),
            Card(
              margin: const EdgeInsets.only(bottom: 18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: cs.secondary),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 16, color: Colors.green),
                        const SizedBox(width: 2),
                        Icon(Icons.circle, size: 16, color: Colors.orange),
                        const SizedBox(width: 2),
                        Icon(Icons.circle, size: 16, color: Colors.red),
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