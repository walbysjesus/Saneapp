import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final role =
              snapshot.data?.data()?['role']?.toString().toLowerCase() ??
              'generador';
          return _NotificationsFeed(userId: user.uid, role: role);
        },
      ),
    );
  }
}

class _NotificationsFeed extends StatelessWidget {
  const _NotificationsFeed({required this.userId, required this.role});

  final String userId;
  final String role;

  @override
  Widget build(BuildContext context) {
    if (role == 'proveedor' || role == 'provider') {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('preferredProviderId', isEqualTo: userId)
            .snapshots(),
        builder: (context, requestsSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .where('proveedorId', isEqualTo: userId)
                .snapshots(),
            builder: (context, paymentsSnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('commercial_chats')
                    .where('providerId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, chatsSnapshot) {
                  if (requestsSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      paymentsSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      chatsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = _buildProviderNotifications(
                    requestsSnapshot.data?.docs ?? const [],
                    paymentsSnapshot.data?.docs ?? const [],
                    chatsSnapshot.data?.docs ?? const [],
                  );
                  return _NotificationsList(items: items);
                },
              );
            },
          );
        },
      );
    }

    if (role == 'supervisor') {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('supervisorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _buildSupervisorNotifications(
            snapshot.data?.docs ?? const [],
          );
          return _NotificationsList(items: items);
        },
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .where('generadorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('commercial_chats')
              .where('generatorId', isEqualTo: userId)
              .snapshots(),
          builder: (context, chatsSnapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                chatsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = _buildGeneratorNotifications(
              snapshot.data?.docs ?? const [],
              chatsSnapshot.data?.docs ?? const [],
            );
            return _NotificationsList(items: items);
          },
        );
      },
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.items});

  final List<_NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay hitos comerciales recientes para mostrar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: item.tint.withValues(alpha: 0.14),
              child: Icon(item.icon, color: item.tint),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.body, style: const TextStyle(height: 1.35)),
            ),
            trailing: Text(
              DateFormat('dd/MM HH:mm').format(item.date),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.body,
    required this.date,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String body;
  final DateTime date;
  final IconData icon;
  final Color tint;
}

List<_NotificationItem> _buildGeneratorNotifications(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> requests,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
) {
  final items = <_NotificationItem>[];
  for (final doc in requests) {
    final data = doc.data();
    final title = data['titulo']?.toString() ?? 'Solicitud';
    final providerName =
        data['preferredProviderName']?.toString() ?? 'un proveedor';
    final stage = data['commercialFlowStage']?.toString();
    final paymentStatus = _normalizePaymentStatus(data['paymentStatus']);
    final selectedOfferId = data['selectedOfferId']?.toString() ?? '';
    final rating = (data['customerRating'] as num?)?.toDouble();

    if (stage == 'technical_sheet_ready_for_provider_quote') {
      items.add(
        _NotificationItem(
          title: 'Ficha técnica lista',
          body:
              'La visita técnica de "$title" ya quedó lista y SaneApp puede empujar la cotización del proveedor objetivo.',
          date: _resolveDate(data),
          icon: Icons.fact_check_outlined,
          tint: const Color(0xFF1C6A8C),
        ),
      );
    }

    if (selectedOfferId.isNotEmpty) {
      items.add(
        _NotificationItem(
          title: 'Oferta adjudicada',
          body:
              'Ya seleccionaste una propuesta comercial para "$title". El siguiente paso visible es el estado del pago.',
          date: _resolveDate(data, preferredField: 'selectedAt'),
          icon: Icons.handshake_outlined,
          tint: const Color(0xFF0C4F31),
        ),
      );
    }

    if (paymentStatus == 'liberado') {
      items.add(
        _NotificationItem(
          title: 'Pago liberado',
          body:
              'El pago de "$title" ya fue liberado al proveedor. Si el servicio terminó, ya puedes registrar tu calificación.',
          date: _resolveDate(data),
          icon: Icons.payments_outlined,
          tint: const Color(0xFF2E7D32),
        ),
      );
    } else if (paymentStatus == 'en_custodia') {
      items.add(
        _NotificationItem(
          title: 'Pago en custodia',
          body:
              'La solicitud "$title" ya tiene adjudicación y el pago está retenido por SaneApp mientras se valida el cierre.',
          date: _resolveDate(data),
          icon: Icons.account_balance_wallet_outlined,
          tint: const Color(0xFF1565C0),
        ),
      );
    } else if (paymentStatus == 'en_disputa') {
      items.add(
        _NotificationItem(
          title: 'Pago en disputa',
          body:
              'SaneApp abrió revisión sobre "$title". El dinero permanece protegido hasta que el caso se resuelva.',
          date: _resolveDate(data),
          icon: Icons.gpp_maybe_outlined,
          tint: const Color(0xFFC24E00),
        ),
      );
    }

    if (rating != null && rating > 0) {
      items.add(
        _NotificationItem(
          title: 'Calificación registrada',
          body:
              'Tu cierre comercial de "$title" ya quedó calificado con ${rating.toStringAsFixed(1)} estrellas.',
          date: _resolveDate(data, preferredField: 'customerRatedAt'),
          icon: Icons.star_outline_rounded,
          tint: const Color(0xFFB77900),
        ),
      );
    } else if ((paymentStatus == 'liberado' ||
            _isTerminalStatus(data['status'])) &&
        (data['selectedProveedorId']?.toString().isNotEmpty == true ||
            providerName.isNotEmpty)) {
      items.add(
        _NotificationItem(
          title: 'Calificación pendiente',
          body:
              'El cierre de "$title" ya puede pasar a validación final. Falta registrar tu experiencia con $providerName.',
          date: _resolveDate(data),
          icon: Icons.rate_review_outlined,
          tint: const Color(0xFF8A5E00),
        ),
      );
    }
  }

  items.addAll(_buildChatNotifications(chats, receiverRole: 'generador'));

  items.sort((a, b) => b.date.compareTo(a.date));
  return items;
}

List<_NotificationItem> _buildProviderNotifications(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> requests,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> payments,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
) {
  final items = <_NotificationItem>[];

  for (final doc in requests) {
    final data = doc.data();
    final title = data['titulo']?.toString() ?? 'Solicitud';
    final stage = data['commercialFlowStage']?.toString();
    if (stage == 'awaiting_provider_response' ||
        stage == 'awaiting_provider_quote') {
      items.add(
        _NotificationItem(
          title: 'Negocio dirigido a tu empresa',
          body:
              'La solicitud "$title" ya está en tu carril comercial y espera reacción u oferta económica de tu lado.',
          date: _resolveDate(data),
          icon: Icons.campaign_outlined,
          tint: const Color(0xFF0C4F31),
        ),
      );
    }
    if (stage == 'technical_sheet_ready_for_provider_quote') {
      items.add(
        _NotificationItem(
          title: 'Ficha técnica disponible',
          body:
              'SaneApp ya terminó la visita previa de "$title". El proveedor ya puede construir la cotización con menos incertidumbre.',
          date: _resolveDate(data),
          icon: Icons.assignment_turned_in_outlined,
          tint: const Color(0xFF1C6A8C),
        ),
      );
    }
    if (data['selectedProveedorId']?.toString().isNotEmpty == true) {
      items.add(
        _NotificationItem(
          title: 'Oferta seleccionada',
          body:
              'Una solicitud comercial ya quedó adjudicada y ahora el foco operativo pasa a pago y cumplimiento.',
          date: _resolveDate(data, preferredField: 'selectedAt'),
          icon: Icons.handshake_outlined,
          tint: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  for (final doc in payments) {
    final data = doc.data();
    final paymentStatus = _normalizePaymentStatus(data['paymentStatus']);
    if (paymentStatus == 'en_disputa') {
      final requestLabel = data['solicitudId']?.toString() ?? 'solicitud';
      items.add(
        _NotificationItem(
          title: 'Cobro en revisión',
          body:
              'El pago asociado a $requestLabel entró en disputa y SaneApp aún no puede liberarlo al proveedor.',
          date: _resolveDate(data, preferredField: 'disputeOpenedAt'),
          icon: Icons.gpp_maybe_outlined,
          tint: const Color(0xFFC24E00),
        ),
      );
      continue;
    }
    if (paymentStatus != 'liberado') {
      continue;
    }
    final requestLabel = data['solicitudId']?.toString() ?? 'solicitud';
    items.add(
      _NotificationItem(
        title: 'Ingreso liberado',
        body:
            'SaneApp ya liberó el pago asociado a $requestLabel para tu empresa.',
        date: _resolveDate(data, preferredField: 'fecha'),
        icon: Icons.attach_money_outlined,
        tint: const Color(0xFF2E7D32),
      ),
    );
  }

  items.addAll(_buildChatNotifications(chats, receiverRole: 'proveedor'));

  items.sort((a, b) => b.date.compareTo(a.date));
  return items;
}

List<_NotificationItem> _buildChatNotifications(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> chats, {
  required String receiverRole,
}) {
  final items = <_NotificationItem>[];
  for (final doc in chats) {
    final data = doc.data();
    final lastSenderRole = data['lastSenderRole']?.toString() ?? '';
    final lastMessage = data['lastMessage']?.toString().trim() ?? '';
    if (lastMessage.isEmpty || lastSenderRole == receiverRole) {
      continue;
    }
    final requestTitle = data['requestTitle']?.toString() ?? 'Solicitud';
    final senderLabel =
        data['providerLabel']?.toString().trim().isNotEmpty == true
        ? (lastSenderRole == 'proveedor'
              ? data['providerLabel'].toString()
              : data['generatorLabel']?.toString() ?? 'Cliente')
        : (lastSenderRole == 'proveedor' ? 'Proveedor' : 'Cliente');
    final preview = lastMessage.length > 78
        ? '${lastMessage.substring(0, 78)}...'
        : lastMessage;
    items.add(
      _NotificationItem(
        title: 'Nuevo mensaje comercial',
        body: '$senderLabel escribió sobre "$requestTitle": $preview',
        date: _resolveDate(data, preferredField: 'lastMessageAt'),
        icon: Icons.mark_chat_unread_outlined,
        tint: const Color(0xFF1C6A8C),
      ),
    );
  }
  return items;
}

List<_NotificationItem> _buildSupervisorNotifications(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> requests,
) {
  final items = <_NotificationItem>[];
  for (final doc in requests) {
    final data = doc.data();
    final title = data['titulo']?.toString() ?? 'Solicitud';
    final supervisorStatus =
        data['supervisorStatus']?.toString() ?? 'pendiente';
    final stage = data['commercialFlowStage']?.toString();

    items.add(
      _NotificationItem(
        title: 'Orden de supervisión activa',
        body:
            'La solicitud "$title" está asignada a supervisión con estado $supervisorStatus.',
        date: _resolveDate(data),
        icon: Icons.verified_user_outlined,
        tint: const Color(0xFF1C6A8C),
      ),
    );

    if (stage == 'awaiting_supervisor_visit' ||
        stage == 'awaiting_supervisor_visit_for_provider_quote') {
      items.add(
        _NotificationItem(
          title: 'Visita pendiente',
          body:
              'La ruta comercial de "$title" depende de la visita técnica antes de avanzar a propuesta o cierre.',
          date: _resolveDate(data),
          icon: Icons.travel_explore_outlined,
          tint: const Color(0xFF8A5E00),
        ),
      );
    }
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  return items;
}

String _normalizePaymentStatus(Object? raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.contains('custodia')) {
    return 'en_custodia';
  }
  return value;
}

bool _isTerminalStatus(Object? raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  return value == 'completada' || value == 'finalizada';
}

DateTime _resolveDate(
  Map<String, dynamic> data, {
  String preferredField = 'commercialFlowUpdatedAt',
}) {
  final candidates = [
    data[preferredField],
    data['updatedAt'],
    data['selectedAt'],
    data['customerRatedAt'],
    data['fecha'],
    data['createdAt'],
  ];
  for (final candidate in candidates) {
    if (candidate is Timestamp) {
      return candidate.toDate();
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
