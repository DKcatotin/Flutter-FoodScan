import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/history_service.dart';
import 'product_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Traduce tu texto/etiqueta de semáforo a color
  Color _semaforoColor(String? nivel) {
    final v = (nivel ?? '').toLowerCase();
    if (v.contains('salud')) return Colors.green;       // "Saludable"
    if (v.contains('moder')) return Colors.amber;       // "Moderado"
    if (v.contains('alto') || v.contains('ultra') || v.contains('riesgo')) {
      return Colors.red;                                // "Alto/Ultraprocesado"
    }
    return Colors.grey;
  }

  // Obtiene el texto a mostrar del semáforo (ajusta a tu campo real)
  String _semaforoTexto(Map<String, dynamic> p) {
    return (p['nivel'] ?? p['semaforo'] ?? p['categoria'] ?? '—').toString();
  }

  // Formato: 26 oct 2025, 20:40
  String _fmtFecha(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)} ${meses[d.month - 1]} ${d.year}, ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final historyService = HistoryService();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ✅ Usaremos SIEMPRE este messenger, no el context del item
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: historyService.getHistoryStream(),
        builder: (context, snapshot) {
          // ⏳ Mientras se establece la conexión con Firestore
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Si hay error (por ejemplo reglas de Firestore)
          if (snapshot.hasError) {
            return const Center(
              child: Text('Ocurrió un error al cargar el historial.'),
            );
          }

          // ✅ Si no hay datos o la colección está vacía para este usuario
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 72,
                      color: cs.outline.withOpacity(0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Todavía no tienes productos escaneados',
                      textAlign: TextAlign.center,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escanea tu primer producto para verlo aquí en tu historial.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        color: tt.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        // Ajusta la ruta al nombre de tu pantalla de escaneo
                        Navigator.pushNamed(context, '/scan');
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear ahora'),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- Aquí sí hay elementos en el historial ---
          final docs = snapshot.data!.docs;

          // --- De-dup en cliente por si existen duplicados antiguos ---
          final byCode = <String, Map<String, dynamic>>{};
          for (final d in docs) {
            final p = d.data();
            final code = (p['codigo'] ?? d.id).toString();

            // Tomamos updatedAt si existe, si no, 'fecha'
            final ts = (p['updatedAt'] ?? p['fecha']);
            final date = (ts is Timestamp)
                ? ts.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            // 🔑 Guardamos también el docId para poder eliminar
            if (!byCode.containsKey(code)) {
              byCode[code] = {
                ...p,
                '_ts': date,
                '_docId': d.id,
              };
            } else {
              final prevDate = byCode[code]!['_ts'] as DateTime;
              if (date.isAfter(prevDate)) {
                byCode[code] = {
                  ...p,
                  '_ts': date,
                  '_docId': d.id,
                };
              }
            }
          }

          final items = byCode.values.toList()
            ..sort((a, b) =>
                (b['_ts'] as DateTime).compareTo(a['_ts'] as DateTime));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final p = items[index];
              final img = (p['imagen'] ?? '').toString();
              final marca = (p['marca'] ?? p['empresa'] ?? '—').toString();
              final nombre = (p['nombre'] ?? 'Sin nombre').toString();
              final nivelTxt = _semaforoTexto(p);
              final nivelColor = _semaforoColor(nivelTxt);
              final fechaTs = (p['updatedAt'] is Timestamp)
                  ? p['updatedAt'] as Timestamp
                  : (p['fecha'] as Timestamp?);
              final fechaStr = _fmtFecha(fechaTs);
              final codigo = (p['codigo'] ?? '').toString();
              final docId = (p['_docId'] ?? '').toString();

              Future<void> _deleteItem() async {
                if (docId.isEmpty) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar del historial'),
                    content: Text(
                      '¿Quieres eliminar "$nombre" de tu historial?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await FirebaseFirestore.instance
                    .collection('historial')
                    .doc(docId)
                    .delete();

                // ✅ Usamos el messenger capturado, no el context del item
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Producto "$nombre" eliminado del historial.'),
                  ),
                );
              }

              return Dismissible(
                key: ValueKey(docId.isNotEmpty ? docId : '$index-$codigo'),
                background: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 24),
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete, color: Colors.white),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  // Usamos el mismo diálogo de confirmación
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar del historial'),
                      content: Text(
                        '¿Quieres eliminar "$nombre" de tu historial?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('historial')
                        .doc(docId)
                        .delete();

                    // ✅ Otra vez, usamos el messenger del Scaffold
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            'Producto "$nombre" eliminado del historial.'),
                      ),
                    );
                  }
                  // Ya manejamos el borrado manualmente
                  return false;
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (codigo.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(codigo: codigo),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: img.isNotEmpty
                                ? Image.network(
                                    img,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.black12,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // Contenido
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Marca / Empresa
                                Text(
                                  marca,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Nombre
                                Text(
                                  nombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 6),

                                // Semáforo
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle,
                                        size: 12, color: nivelColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      nivelTxt.isEmpty ? '—' : nivelTxt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Fecha
                                Text(
                                  fechaStr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Botón borrar rápido
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: cs.error,
                            tooltip: 'Eliminar de historial',
                            onPressed: _deleteItem,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
