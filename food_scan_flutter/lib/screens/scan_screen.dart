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
  bool processing = false; // Evita múltiples detecciones
  final MobileScannerController cameraController = MobileScannerController();

  Future<void> onDetect(BarcodeCapture barcode) async {
    // ⛔ Evitar procesar mientras ya está procesando
    if (!scanning || processing || barcode.barcodes.isEmpty) return;
    
    setState(() => processing = true);

    final code = barcode.barcodes.first.rawValue ?? '';
    
    if (code.isEmpty) {
      setState(() => processing = false);
      return;
    }

    // 🔍 Mostrar diálogo de carga
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Buscando producto...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // 🔍 1. Buscar en Firestore primero
      final firestoreQuery = await FirebaseFirestore.instance
          .collection('productos')
          .where('codigo', isEqualTo: code)
          .limit(1)
          .get();

      Map<String, dynamic>? productData;

      if (firestoreQuery.docs.isNotEmpty) {
        // ✅ Producto encontrado en Firestore
        productData = firestoreQuery.docs.first.data();
        print('✅ Producto encontrado en Firestore');
      } else {
        // 🌍 2. Buscar en OpenFoodFacts
        print('🔍 Buscando en OpenFoodFacts...');
        productData = await getProductFromApi(code);
        
        if (productData != null) {
          print('✅ Producto encontrado en OpenFoodFacts y guardado');
        }
      }

      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      if (productData != null) {
        // ✅ Navegar a detalles
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(codigo: code),
            ),
          );
        }
      } else {
        // ❌ Producto no encontrado
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('❌ Producto no encontrado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se encontró información para este código de barras.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Código: $code',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => processing = false);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // ⚠️ Error general
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar producto: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        setState(() => processing = false);
      }
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
          // 🔦 Control de flash
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
          
          // 🔄 Cambiar cámara
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 📷 Escáner
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: onDetect,
                ),
                
                // Marco visual
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 📝 Instrucciones
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enfoca el código de barras del producto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    processing ? 'Procesando...' : 'Listo para escanear',
                    style: TextStyle(
                      color: processing ? Colors.amber : Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}