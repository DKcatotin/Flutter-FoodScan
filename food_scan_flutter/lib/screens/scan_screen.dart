import 'dart:io';
import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart' as mscan;
import 'package:image_picker/image_picker.dart';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:google_mlkit_commons/google_mlkit_commons.dart' as mlcommons;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/openfood_service.dart';
import '../services/history_service.dart';
import 'product_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

// Ícono “barcode” minimalista (barras) para UI
class _BarcodeGlyph extends StatelessWidget {
  final Color color;
  final double height;
  const _BarcodeGlyph({required this.color, this.height = 28}); // <- quitamos super.key

  @override
  Widget build(BuildContext context) {
    final bars = <double>[2, 1, 1, 3, 1, 2, 2, 1, 3, 1, 1, 2, 1, 3, 2, 1];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < bars.length; i++)
          Container(
            width: bars[i] * 2.0,
            height: height,
            color: i.isEven ? color : Colors.transparent,
            margin: const EdgeInsets.symmetric(horizontal: 0.3),
          ),
      ],
    );
  }
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  bool processing = false; // evita múltiples detecciones
  bool cameraReady = false;

  final mscan.MobileScannerController cameraController =
      mscan.MobileScannerController(
    facing: mscan.CameraFacing.back,
    detectionSpeed: mscan.DetectionSpeed.normal,
    torchEnabled: false,
  );

  final HistoryService historyService = HistoryService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _warmUpCamera(); // importante al arrancar
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  // Pausar / reanudar al cambiar de estado de app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      cameraController.stop();
      cameraReady = false;
    } else if (state == AppLifecycleState.resumed) {
      _restartCamera();
    }
  }

  Future<void> _warmUpCamera() async {
    try {
      final facing = cameraController.cameraFacingState.value;
      if (facing != mscan.CameraFacing.back) {
        await cameraController.switchCamera();
      }
      await cameraController.stop();
      await Future.delayed(const Duration(milliseconds: 150));
      await cameraController.start();
    } catch (_) {
      await _restartCamera();
    }
  }

  Future<void> _restartCamera() async {
    try {
      await cameraController.stop();
      await Future.delayed(const Duration(milliseconds: 150));
      await cameraController.start();
    } catch (_) {}
  }

  // ====== LIVE SCAN ======
 Future<void> onDetect(mscan.BarcodeCapture barcode) async {
  if (processing || barcode.barcodes.isEmpty) return;

  final code = barcode.barcodes.first.rawValue ?? '';
  if (code.isEmpty) return;

  setState(() => processing = true);

  // 🔴 Detenemos la cámara para que no siga escaneando
  await cameraController.stop();
  cameraReady = false;

  await _handleCodeFlow(code);
}


  // ====== IMAGE SCAN (ML Kit) ======
  Future<void> _processImage(File imageFile) async {
    setState(() => processing = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Procesando imagen...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final inputImage = mlcommons.InputImage.fromFilePath(imageFile.path);
      final barcodeScanner = mlkit.BarcodeScanner(
        formats: [
          mlkit.BarcodeFormat.ean13,
          mlkit.BarcodeFormat.ean8,
          mlkit.BarcodeFormat.code128,
        ],
      );

      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      if (mounted) Navigator.pop(context); // cerrar loading

      if (barcodes.isEmpty) {
        _showNotFound('No se detectó ningún código de barras en la imagen.');
        setState(() => processing = false);
        return;
      }

      final first = barcodes.firstWhere(
        (b) => (b.rawValue ?? '').isNotEmpty,
        orElse: () => barcodes.first,
      );
      final code = first.rawValue ?? '';

      if (code.isEmpty) {
        _showNotFound('No se pudo leer un valor de código válido.');
        setState(() => processing = false);
        return;
      }

      await _handleCodeFlow(code);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // cerrar loading si estaba abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => processing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) await _processImage(File(picked.path));
  }

  Future<void> _pickFromCamera() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) await _processImage(File(picked.path));
  }

  // ====== Flujo común luego de tener el código ======
  Future<void> _handleCodeFlow(String code) async {
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
      Map<String, dynamic>? productData;

      // 1) Buscar en Firestore
      final firestoreQuery = await FirebaseFirestore.instance
          .collection('productos')
          .where('codigo', isEqualTo: code)
          .limit(1)
          .get();

      if (firestoreQuery.docs.isNotEmpty) {
        productData = firestoreQuery.docs.first.data();
      } else {
        // 2) OpenFoodFacts
        productData = await getProductFromApi(code);
      }

      if (mounted) Navigator.pop(context); // cerrar loading

      if (productData != null) {
        await historyService.addToHistory(productData);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(codigo: code),
            ),
          );
        }
      } else {
        if (mounted) {
          _showNotFound('No se encontró información para el código: $code');
       // 🔁 Volver a encender la cámara si seguimos en esta pantalla
    await _restartCamera();
    setState(() => cameraReady = true);
  }
}
   } catch (e) {
  if (mounted) {
    Navigator.pop(context); // cerrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al buscar producto: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
    // 🔁 Reanudar cámara si seguimos aquí
    await _restartCamera();
    setState(() => cameraReady = true);
  }
} finally {
  if (mounted) setState(() => processing = false);
}

  }

  void _showNotFound(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Producto no encontrado'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        actions: [
          // 🔦 Flash
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == mscan.TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state == mscan.TorchState.on ? Colors.yellow : null,
                );
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
         // 🔄 Cambiar cámara (versión sin errores)
IconButton(
  icon: const Icon(Icons.cameraswitch),
  onPressed: () async {
    try {
      // Solo alternamos la cámara — MobileScanner se encarga del start/stop interno
      await cameraController.switchCamera();

      // Pequeño delay visual para el cambio
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          cameraReady = true;
        });
      }

      // Mostrar aviso opcional
      final facing = cameraController.cameraFacingState.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            facing == mscan.CameraFacing.front
                ? 'Cámara frontal activada 📸'
                : 'Cámara trasera activada 🔙',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar de cámara:\n$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  },
),
        ],
      ),
      body: Column(
        children: [
          // 📷 Live scanner
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                mscan.MobileScanner(
                  controller: cameraController,
                  onDetect: onDetect,
                  // onPermissionSet: ...  <-- eliminado (no existe en tu versión)
                  onScannerStarted: (arguments) {
                    if (mounted) setState(() => cameraReady = true);
                  },
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 8),
                          Text('$error'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _restartCamera,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar cámara'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Marco visual tipo "barcode"
                if (cameraReady)
                  Container(
                    width: 320,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                // Barra inferior (galería / cámara)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: Opacity(
                      opacity: 0.85,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Elegir de galería',
                              onPressed: processing ? null : _pickFromGallery,
                              icon: const Icon(Icons.photo_library_outlined),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Tomar foto',
                              onPressed: processing ? null : _pickFromCamera,
                              icon: const Icon(Icons.photo_camera_outlined),
                            ),
                          ],
                        ),
                      ),
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
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: cs.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BarcodeGlyph(color: cs.primary, height: 28),
                  const SizedBox(height: 12),
                  Text(
                    processing ? 'Procesando…' : 'Apunta al código o elige una imagen',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Detecta automáticamente en vivo. También puedes usar una foto de tu galería o tomar una.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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
