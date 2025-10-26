import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/openfood_service.dart';
import 'product_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool scanning = true;
  final MobileScannerController cameraController = MobileScannerController();

  Future<void> onDetect(BarcodeCapture barcode) async {
    if (!scanning || barcode.barcodes.isEmpty) return;
    setState(() => scanning = false);

    final code = barcode.barcodes.first.rawValue ?? '';
    Map<String, dynamic>? product;

    try {
      // 🔍 Busca primero en Firestore
      final query = await FirebaseFirestore.instance
          .collection('productos')
          .where('codigo', isEqualTo: code)
          .get();

      if (query.docs.isNotEmpty) {
        product = query.docs.first.data();
      } else {
        // 🌍 Si no está, busca en Open Food Facts
        product = await getProductFromApi(code);
      }

      if (!mounted) return;
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => ProductDetailScreen(codigo: code)),
);

      if (product != null) {
        // Si se encontró en Firestore o Open Food Facts
        setState(() => scanning = true);

      } else {
        // Si no se encontró en ningún lado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto no encontrado')),
        );
        setState(() => scanning = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => scanning = true);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state == TorchState.on ? Colors.yellow : Colors.grey,
                );
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: cameraController,
              onDetect: onDetect,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Escanea el código de barras de un alimento.'),
          ),
        ],
      ),
    );
  }
}
