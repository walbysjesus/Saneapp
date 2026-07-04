

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:saneapp_pro_nuevo/l10n/app_localizations.dart';


class DocumentReviewPanel extends StatefulWidget {
  const DocumentReviewPanel({super.key});

  @override
  State<DocumentReviewPanel> createState() => _DocumentReviewPanelState();
}

class _DocumentReviewPanelState extends State<DocumentReviewPanel> {
  static const int pageSize = 10;
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _docs = [];

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    Query query = FirebaseFirestore.instance
        .collection('provider_documents')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }
    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      setState(() {
        _docs.addAll(snap.docs);
        _lastDoc = snap.docs.last;
        if (snap.docs.length < pageSize) _hasMore = false;
      });
    } else {
      setState(() => _hasMore = false);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RevisiÃ³n de documentos')),
      body: _isLoading && _docs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? const Center(child: Text('No hay documentos pendientes.'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (_hasMore && !_isLoading && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      _fetchNextPage();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: _docs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _docs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final doc = _docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final usuario = data['userName'] ?? data['userId'] ?? 'Usuario';
                      final documento = data['type'] ?? 'Documento';
                      final url = data['url'] ?? '';
                      return Semantics(
                        label: 'Documento: $documento, Usuario: $usuario',
                        child: Card(
                          color: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(documento, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('Usuario: $usuario'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Aprobar',
                                  onPressed: () async {
                                    await doc.reference.update({'status': 'approved'});
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Documento aprobado'), backgroundColor: Colors.green),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Rechazar',
                                  onPressed: () async {
                                    await doc.reference.update({'status': 'rejected'});
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Documento rechazado'), backgroundColor: Colors.red),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () async {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No se pudo abrir el documento'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            minVerticalPadding: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


