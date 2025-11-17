import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Evita duplicado consecutivo en la misma sesión
  String? _lastScannedCode;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('historial');

  /// === UPSERT POR 'codigo' POR USUARIO ===
  /// Cada usuario tiene sus propios productos, usando:
  /// doc path => historial/{uid}_{codigo}
  Future<void> upsertScan(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ No hay usuario autenticado. No se puede guardar historial.");
      return;
    }

    final uid = user.uid;
    final code = (product['codigo'] ?? '').toString();

    if (code.isEmpty) return;

    // Evitar duplicado consecutivo
    if (_lastScannedCode == code) {
      print('⚠️ Producto $code ya fue escaneado recientemente, no se agrega');
      return;
    }
    _lastScannedCode = code;

    // ID único por usuario + producto
    final docId = '${uid}_$code';

    await _col.doc(docId).set({
      'userId': uid,                 // 👈 MUY IMPORTANTE
      'codigo': product['codigo'],
      'nombre': product['nombre'],
      'marca': product['marca'],
      'imagen': product['imagen'],
      'calorias': product['calorias'],
      'azucar': product['azucar'],
      'grasas': product['grasas'],
      'sodio': product['sodio'],
      'ingredientes': product['ingredientes'],

      if (product.containsKey('nivel')) 'nivel': product['nivel'],
      if (product.containsKey('semaforo')) 'semaforo': product['semaforo'],

      // Fechas
      'fecha': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Producto ${product['nombre']} guardado/actualizado (upsert) para user $uid');
  }

  /// Compatibilidad con funciones antiguas
  Future<void> addToHistory(Map<String, dynamic> product) => upsertScan(product);

  /// === STREAM SOLO DEL USUARIO ACTUAL ===
  Stream<QuerySnapshot<Map<String, dynamic>>> getHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ No hay usuario autenticado para leer historial.");
      return const Stream.empty();
    }

    return _col
        .where('userId', isEqualTo: user.uid)     // 👈 FILTRO POR USUARIO
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  void resetLastScanned() {
    _lastScannedCode = null;
  }
}
