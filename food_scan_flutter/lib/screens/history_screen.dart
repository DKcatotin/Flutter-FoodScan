import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/history_service.dart';
import 'product_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = HistoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyService.getHistoryStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Aún no has escaneado productos'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final p = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: p['imagen'] != null && p['imagen'] != ''
                      ? Image.network(p['imagen'], width: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(p['nombre'] ?? 'Sin nombre'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['marca'] ?? 'Marca desconocida'),
                      const SizedBox(height: 4),
                      Text(
                        'Ingredientes: ${(p['ingredientes'] as List?)?.take(3).join(", ") ?? "N/A"}...',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(codigo: p['codigo']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
