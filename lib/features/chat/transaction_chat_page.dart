import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/commercial_guardrails_service.dart';
import '../../services/provider_commercial_reputation_service.dart';

class TransactionChatPage extends StatefulWidget {
  const TransactionChatPage({
    super.key,
    required this.requestId,
    required this.requestTitle,
    required this.generatorId,
    required this.providerId,
    required this.generatorLabel,
    required this.providerLabel,
  });

  final String requestId;
  final String requestTitle;
  final String generatorId;
  final String providerId;
  final String generatorLabel;
  final String providerLabel;

  @override
  State<TransactionChatPage> createState() => _TransactionChatPageState();
}

class _TransactionChatPageState extends State<TransactionChatPage> {
  static const _brandGreen = Color(0xFF0C4F31);

  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();
    if (user == null || text.isEmpty) {
      return;
    }

    final isGenerator = user.uid == widget.generatorId;
    final isProvider = user.uid == widget.providerId;
    if (!isGenerator && !isProvider) {
      return;
    }
    final senderRole = isGenerator ? 'generador' : 'proveedor';
    final guardrail = CommercialGuardrailsService.inspectMessage(text);
    if (guardrail.blocked) {
      await CommercialGuardrailsService.registerBlockedAttempt(
        requestId: widget.requestId,
        requestTitle: widget.requestTitle,
        senderId: user.uid,
        senderRole: senderRole,
        reasons: guardrail.reasons,
        rawText: text,
      );
      if (isProvider) {
        await ProviderCommercialReputationService.registerPolicyViolation(
          providerId: widget.providerId,
          reason: 'contact_exchange_attempt',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mensaje bloqueado: SaneApp no permite compartir ${guardrail.reasons.join(', ')}. ${CommercialGuardrailsService.policyMessage}',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('commercial_chats')
          .doc(widget.requestId);
      final messageRef = chatRef.collection('messages').doc();
      final senderLabel = isGenerator
          ? widget.generatorLabel
          : widget.providerLabel;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(chatRef, {
          'requestId': widget.requestId,
          'requestTitle': widget.requestTitle,
          'generatorId': widget.generatorId,
          'providerId': widget.providerId,
          'generatorLabel': widget.generatorLabel,
          'providerLabel': widget.providerLabel,
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageBy': user.uid,
          'lastSenderRole': senderRole,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(messageRef, {
          'text': text,
          'senderId': user.uid,
          'senderRole': senderRole,
          'senderLabel': senderLabel,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      _messageController.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isParticipant =
        currentUser != null &&
        (currentUser.uid == widget.generatorId ||
            currentUser.uid == widget.providerId);
    final currentRole = currentUser?.uid == widget.providerId
        ? 'proveedor'
        : 'generador';
    final visibleGeneratorLabel =
        CommercialGuardrailsService.protectedLabelForRole(
          'generador',
          widget.generatorLabel,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Chat comercial'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.requestTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$visibleGeneratorLabel  |  ${widget.providerLabel}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE7DF)),
                  ),
                  child: const Text(
                    'Canal protegido: SaneApp no libera teléfono, correo ni contacto directo del generador. La facturación y la trazabilidad quedan dentro de la plataforma.',
                    style: TextStyle(color: Colors.black54, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('commercial_chats')
                  .doc(widget.requestId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no hay mensajes. Este canal sirve para alinear alcance, tiempos y condiciones comerciales dentro de SaneApp.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, height: 1.4),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final mine = currentUser?.uid == data['senderId'];
                    final createdAt = data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp).toDate()
                        : null;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 360),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFFE7F4EB) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: mine
                                ? const Color(0xFFCAE0D0)
                                : const Color(0xFFDCE7DF),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              () {
                                final senderRole =
                                    data['senderRole']?.toString() ?? '';
                                if (currentRole == 'proveedor' &&
                                    senderRole == 'generador') {
                                  return CommercialGuardrailsService.protectedLabelForRole(
                                    'generador',
                                    widget.generatorLabel,
                                  );
                                }
                                return data['senderLabel']?.toString() ??
                                    data['senderRole']?.toString() ??
                                    'Participante';
                              }(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['text']?.toString() ?? '',
                              style: const TextStyle(height: 1.35),
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${createdAt.day}/${createdAt.month} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFDCE7DF))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: isParticipant && !_sending,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Escribe una aclaración comercial. No compartas teléfono, correo ni canales externos.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: isParticipant && !_sending ? _sendMessage : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
