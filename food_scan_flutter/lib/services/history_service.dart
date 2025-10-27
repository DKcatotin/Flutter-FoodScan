import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  final _db = FirebaseFirestore.instance;
  String? _lastScannedCode; // Guarda el último código escaneado

  /// Guarda producto en historial (sin duplicar consecutivos)
  Future<void> addToHistory(Map<String, dynamic> product) async {
    final code = product['codigo'];
    if (code == null) return;

    // Evitar duplicado consecutivo
    if (_lastScannedCode == code) {
      print('⚠️ Producto $code ya fue escaneado recientemente, no se agrega');
      return;
    }

    _lastScannedCode = code;

    // Guardar en la colección "historial"
    await _db.collection('historial').add({
      'codigo': product['codigo'],
      'nombre': product['nombre'],
      'marca': product['marca'],
      'imagen': product['imagen'],
      'calorias': product['calorias'],
      'azucar': product['azucar'],
      'grasas': product['grasas'],
      'sodio': product['sodio'],
      'ingredientes': product['ingredientes'],
      'fecha': FieldValue.serverTimestamp(),
    });

    print('✅ Producto ${product['nombre']} agregado al historial');
  }

  /// Obtiene el historial completo (ordenado por fecha descendente)
  Stream<QuerySnapshot<Map<String, dynamic>>> getHistoryStream() {
    return _db
        .collection('historial')
        .orderBy('fecha', descending: true)
        .snapshots();
  }
}
