import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Evita duplicado consecutivo en la misma sesión
  String? _lastScannedCode;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('historial');

  /// === NUEVO: UPSERT POR 'codigo' (sin duplicados en la base) ===
  /// - Si el documento con ese 'codigo' existe, se ACTUALIZA (merge).
  /// - Si no existe, se CREA.
  /// - Siempre actualiza 'updatedAt' para ordenar por más reciente.
  Future<void> upsertScan(Map<String, dynamic> product) async {
    final code = (product['codigo'] ?? '').toString();
    if (code.isEmpty) return;

    // Evitar duplicado consecutivo (tu lógica original)
    if (_lastScannedCode == code) {
      // Puedes quitar este print si no lo deseas
      // ignore: avoid_print
      print('⚠️ Producto $code ya fue escaneado recientemente, no se agrega');
      return;
    }
    _lastScannedCode = code;

    // Escritura con merge: NO se duplican docs con el mismo código
    await _col.doc(code).set({
      // Datos del producto (tus campos originales)
      'codigo': product['codigo'],
      'nombre': product['nombre'],
      'marca': product['marca'],
      'imagen': product['imagen'],
      'calorias': product['calorias'],
      'azucar': product['azucar'],
      'grasas': product['grasas'],
      'sodio': product['sodio'],
      'ingredientes': product['ingredientes'],

      // Si manejas semáforo, puedes enviar 'nivel' o 'semaforo'
      if (product.containsKey('nivel')) 'nivel': product['nivel'],
      if (product.containsKey('semaforo')) 'semaforo': product['semaforo'],

      // Fechas
      // 'fecha' era tu campo previo; lo mantenemos por compatibilidad
      'fecha': FieldValue.serverTimestamp(),
      // 'updatedAt' para ordenar siempre por el más reciente
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ignore: avoid_print
    print('✅ Producto ${product['nombre']} guardado/actualizado (upsert)');
  }

  /// === COMPATIBILIDAD: si en algún lugar llamas addToHistory(...) ===
  /// Redirige al upsert para no duplicar en la base.
  Future<void> addToHistory(Map<String, dynamic> product) => upsertScan(product);

  /// Stream del historial, ordenado por el más reciente.
  /// Usa 'updatedAt' (los antiguos sin este campo quedarán al final).
  Stream<QuerySnapshot<Map<String, dynamic>>> getHistoryStream() {
    return _col.orderBy('updatedAt', descending: true).snapshots();
  }

  /// Permite resetear el "anti-duplicado consecutivo" (opcional)
  void resetLastScanned() {
    _lastScannedCode = null;
  }
}
