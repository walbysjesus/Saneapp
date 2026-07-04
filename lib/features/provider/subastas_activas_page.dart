import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/request_image_gallery.dart';
import '../supervision/supervision_artifacts.dart';
import 'provider_access_guard.dart';
import 'provider_quote_form_page.dart';

class SubastasActivasPage extends StatelessWidget {
  const SubastasActivasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subastas activas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('type', isEqualTo: 'subasta')
            .where('status', isEqualTo: 'activa')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay subastas activas.'));
          }
          final subastas = snapshot.data!.docs;
          return ListView.separated(
            itemCount: subastas.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = subastas[index].data() as Map<String, dynamic>;
              final subastaId = subastas[index].id;
              final deadline = (data['deadline'] as Timestamp?)?.toDate();
              final technicalSurveySheet = resolveTechnicalSurveySheet(data);
              final requestImages =
                  (data['requestImageUrls'] as List?)?.cast<String>() ?? const [];
              return ListTile(
                leading: const Icon(Icons.gavel),
                title: Text(data['titulo'] ?? 'Subasta sin tÃ­tulo'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (deadline != null)
                      Text(
                        'Cierra: ${DateFormat('dd/MM/yyyy HH:mm').format(deadline)}',
                      ),
                    if (technicalSurveySheet != null)
                      Text(
                        'Ficha técnica: ${mapTechnicalSheetStatusLabel(technicalSurveySheet['status']?.toString())}',
                        style: const TextStyle(
                          color: Color(0xFF1E7A4B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (requestImages.isNotEmpty)
                      Text('Adjuntos del generador: ${requestImages.length}'),
                    _LowestOfferWidget(subastaId: subastaId),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Ofertar'),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    final canOperate = await ensureProviderCanOperate(
                      context,
                      message:
                          'Debes completar tu registro de proveedor para poder ofertar.',
                    );
                    if (!canOperate) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProviderQuoteFormPage(
                          solicitudId: subastaId,
                          requestData: data,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(data['titulo'] ?? 'Detalle'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['descripcion'] ?? ''),
                            if (requestImages.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              RequestImageGallery(
                                imageUrls: requestImages,
                                title: 'Imágenes compartidas por el generador',
                              ),
                            ],
                            if (technicalSurveySheet != null) ...[
                              const SizedBox(height: 16),
                              TechnicalSurveySheetCard(
                                sheet: technicalSurveySheet,
                                providerFacing: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cerrar'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LowestOfferWidget extends StatelessWidget {
  final String subastaId;
  const _LowestOfferWidget({required this.subastaId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ofertas')
          .where('solicitudId', isEqualTo: subastaId)
          .orderBy('price')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Sin ofertas aÃºn');
        }
        final oferta = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return Text('Oferta mÃ¡s baja: ${oferta['price'] ?? '-'}');
      },
    );
  }
}
