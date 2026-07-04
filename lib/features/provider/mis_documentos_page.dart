import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);
const _cardBorder = Color(0xFFDDE6E0);

class MisDocumentosPage extends StatelessWidget {
  const MisDocumentosPage({super.key});

  List<Map<String, String>> _documentsFromProviderData(
    Map<String, dynamic>? providerData,
  ) {
    if (providerData == null) {
      return const [];
    }
    const definitions = [
      ('rutUrl', 'RUT'),
      ('camaraComercioUrl', 'Cámara de comercio'),
      ('cedulaUrl', 'Cédula representante'),
      ('certificadoBancarioUrl', 'Certificado bancario'),
      ('licenciaAmbientalUrl', 'Licencia ambiental'),
    ];

    return definitions
        .where((item) => (providerData[item.$1] as String?)?.isNotEmpty == true)
        .map(
          (item) => {'nombre': item.$2, 'url': providerData[item.$1] as String},
        )
        .toList();
  }

  Future<void> _openDocument(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el documento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Mis documentos'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: () async {
          final results = await Future.wait([
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('documents')
                .get(),
            FirebaseFirestore.instance
                .collection('providers')
                .doc(user.uid)
                .get(),
          ]);

          final documentsSnapshot =
              results[0] as QuerySnapshot<Map<String, dynamic>>;
          final providerSnapshot =
              results[1] as DocumentSnapshot<Map<String, dynamic>>;

          final subcollectionDocs = documentsSnapshot.docs
              .map(
                (doc) => {
                  'nombre': (doc.data()['nombre'] as String?) ?? 'Documento',
                  'url': (doc.data()['url'] as String?) ?? '',
                },
              )
              .where((doc) => doc['url']!.isNotEmpty)
              .toList();

          if (subcollectionDocs.isNotEmpty) {
            return subcollectionDocs;
          }

          return _documentsFromProviderData(providerSnapshot.data());
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay documentos subidos.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder),
                ),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _brandGreenSoft.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: _brandGreenSoft,
                    ),
                  ),
                  title: Text(data['nombre'] ?? 'Documento'),
                  subtitle: Text(
                    data['url'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, color: _brandGreen),
                    onPressed: () => _openDocument(context, data['url']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        tooltip: 'Subir documento',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La carga de documentos se gestiona desde el perfil proveedor.',
              ),
            ),
          );
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
