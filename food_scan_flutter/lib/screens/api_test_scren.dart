import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/openfood_service.dart';
import 'dart:convert';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  
  bool loading = false;
  String? resultMessage;
  Map<String, dynamic>? productData;
  String? rawJson;
  bool showRawJson = false;

  // 🧪 Códigos de barras de prueba conocidos
  final List<Map<String, String>> testBarcodes = [
    {
      'code': '7501055363308',
      'name': 'Coca Cola (México)',
      'description': 'Bebida gaseosa muy popular'
    },
    {
      'code': '5449000000996',
      'name': 'Coca Cola (Internacional)',
      'description': 'Código internacional'
    },
    {
      'code': '7501055308453',
      'name': 'Pepsi (México)',
      'description': 'Bebida gaseosa'
    },
    {
      'code': '3017620422003',
      'name': 'Nutella',
      'description': 'Crema de avellanas'
    },
    {
      'code': '8076809513128',
      'name': 'Ferrero Rocher',
      'description': 'Chocolate premium'
    },
    {
      'code': '7501055303908',
      'name': 'Sabritas Original',
      'description': 'Papas fritas'
    },
  ];

  Future<void> testBarcode(String barcode) async {
    setState(() {
      loading = true;
      resultMessage = null;
      productData = null;
      rawJson = null;
    });

    try {
      print('🔍 Probando código: $barcode');
      
      // Llamar al servicio
      final result = await getProductFromApi(barcode);
      
      if (result != null) {
        setState(() {
          productData = result;
          rawJson = const JsonEncoder.withIndent('  ').convert(result);
          resultMessage = '✅ Producto encontrado y procesado correctamente';
          loading = false;
        });
        print('✅ Producto encontrado: ${result['nombre']}');
      } else {
        setState(() {
          resultMessage = '❌ Producto no encontrado en OpenFoodFacts';
          loading = false;
        });
        print('❌ No se encontró el producto');
      }
    } catch (e, stackTrace) {
      setState(() {
        resultMessage = '🔴 ERROR: $e';
        loading = false;
      });
      print('🔴 Error completo: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Widget buildProductPreview() {
    if (productData == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📦 Vista Previa del Producto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Código', productData!['codigo'] ?? 'N/A'),
            _buildInfoRow('Nombre', productData!['nombre'] ?? 'N/A'),
            _buildInfoRow('Marca', productData!['marca'] ?? 'N/A'),
            _buildInfoRow('Calorías', '${productData!['calorias']} kcal'),
            _buildInfoRow('Azúcares', '${productData!['azucar']}g'),
            _buildInfoRow('Grasas', '${productData!['grasas']}g'),
            _buildInfoRow('Sal', '${productData!['sodio']}g'),
            const SizedBox(height: 12),
            const Text(
              '📋 Ingredientes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              (productData!['ingredientes'] as List).join(', '),
              style: const TextStyle(fontSize: 12),
            ),
            if (productData!['imagen'] != null &&
                productData!['imagen'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '🖼️ Imagen del producto:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  productData!['imagen'],
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('Error al cargar imagen'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Pruebas de API'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 Instrucciones
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta pantalla te permite probar si la API de OpenFoodFacts está funcionando correctamente.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🧪 CÓDIGOS DE PRUEBA
            const Text(
              '🧪 Códigos de Prueba Conocidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ...testBarcodes.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    item['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['description']!),
                      Text(
                        'Código: ${item['code']}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => testBarcode(item['code']!),
                  ),
                  onTap: () {
                    _barcodeController.text = item['code']!;
                  },
                ),
              );
            }),

            const SizedBox(height: 24),

            // ✍️ PRUEBA MANUAL
            const Text(
              '✍️ Probar Código Manual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _barcodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Código de barras',
                hintText: 'Ingresa un código...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _barcodeController.clear(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  loading ? 'Consultando API...' : 'Probar Código',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: loading
                    ? null
                    : () {
                        if (_barcodeController.text.isNotEmpty) {
                          testBarcode(_barcodeController.text);
                        }
                      },
              ),
            ),

            // 📊 RESULTADOS
            if (resultMessage != null) ...[
              const SizedBox(height: 20),
              Card(
                color: resultMessage!.contains('✅')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        resultMessage!.contains('✅')
                            ? Icons.check_circle
                            : Icons.error,
                        color: resultMessage!.contains('✅')
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          resultMessage!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 📦 VISTA PREVIA
            buildProductPreview(),

            // 📄 JSON RAW
            if (rawJson != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📄 JSON Raw (para debugging)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      showRawJson ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(showRawJson ? 'Ocultar' : 'Mostrar'),
                    onPressed: () {
                      setState(() => showRawJson = !showRawJson);
                    },
                  ),
                ],
              ),
              if (showRawJson)
                Card(
                  color: Colors.grey[900],
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: rawJson!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('JSON copiado al portapapeles'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SelectableText(
                          rawJson!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }
}