import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistorialProveedorPage extends StatelessWidget {
  const HistorialProveedorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No autenticado.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('selectedProveedorId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completada')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay historial disponible.'));
          }
          final historial = snapshot.data!.docs;
          return ListView.separated(
            itemCount: historial.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = historial[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(data['titulo'] ?? 'Servicio sin tÃ­tulo'),
                subtitle: Text(data['descripcion'] ?? ''),
                trailing: Text(
                  (data['fecha'] != null && data['fecha'] is Timestamp)
                      ? (data['fecha'] as Timestamp).toDate().toString().substring(0, 16)
                      : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

