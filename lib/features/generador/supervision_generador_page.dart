import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../supervision/supervision_artifacts.dart';
import 'solicitud_detalle_page.dart';

class SupervisionGeneradorPage extends StatefulWidget {
  static const Color _brandGreen = Color(0xFF0C4F31);
  static const Color _brandGreenSoft = Color(0xFF1E7A4B);
  static const Color _alertColor = Color(0xFFC24E00);

  const SupervisionGeneradorPage({super.key});

  @override
  State<SupervisionGeneradorPage> createState() =>
      _SupervisionGeneradorPageState();
}

class _SupervisionGeneradorPageState extends State<SupervisionGeneradorPage> {
  String _selectedFilter = 'todos';

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final fallbackUser = appState.currentUser;
    final userId = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser?.uid ?? fallbackUser?.uid
        : fallbackUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Supervisión SaneApp'),
        backgroundColor: SupervisionGeneradorPage._brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  SupervisionGeneradorPage._brandGreen,
                  SupervisionGeneradorPage._brandGreenSoft,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control técnico cuando realmente importa',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Solicita diagnóstico previo o supervisión de ejecución con trazabilidad.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'El supervisor es personal directo de SaneApp: visita el sitio asignado, levanta información técnica, da asesoría breve al generador y deja evidencia útil para que el proveedor cotice con más precisión.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Modalidades disponibles',
            subtitle:
                'Elige cómo el equipo técnico interno de SaneApp va a acompañar, verificar y documentar el servicio.',
          ),
          const SizedBox(height: 12),
          _SupervisionModeCard(
            title: 'Preinspección técnica previa a cotización',
            subtitle:
                'Un supervisor de SaneApp visita el punto, identifica accesos, residuos, riesgos y condiciones reales para construir una ficha técnica útil antes de cotizar.',
            badgeLabel: 'Diagnóstico previo',
            accentColor: SupervisionGeneradorPage._brandGreenSoft,
            icon: Icons.fact_check_outlined,
            onTap: () {
              Navigator.of(context).pushNamed(
                '/crear_solicitud',
                arguments: const {
                  'supervisorType': 'prequote_diagnostic',
                  'supervisorRequested': true,
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _SupervisionModeCard(
            title: 'Supervisión de ejecución y calidad',
            subtitle:
                'SaneApp acompaña la ejecución, verifica buenas prácticas del proveedor, toma evidencias y deja trazabilidad integral del servicio prestado.',
            badgeLabel: 'Trazabilidad y calidad',
            accentColor: SupervisionGeneradorPage._alertColor,
            icon: Icons.verified_user_outlined,
            onTap: () {
              Navigator.of(context).pushNamed(
                '/crear_solicitud',
                arguments: const {
                  'supervisorType': 'execution_traceability',
                  'supervisorRequested': true,
                },
              );
            },
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Servicios con supervisión',
            subtitle:
                'Consulta solicitudes donde ya pediste acompañamiento del personal técnico de SaneApp.',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _selectedFilter == 'todos',
                  onTap: () => setState(() => _selectedFilter = 'todos'),
                ),
                _FilterChip(
                  label: 'Pendiente asignación',
                  selected: _selectedFilter == 'pendiente_asignacion',
                  onTap: () =>
                      setState(() => _selectedFilter = 'pendiente_asignacion'),
                ),
                _FilterChip(
                  label: 'Asignado',
                  selected: _selectedFilter == 'asignado',
                  onTap: () => setState(() => _selectedFilter = 'asignado'),
                ),
                _FilterChip(
                  label: 'En acompañamiento',
                  selected: _selectedFilter == 'en_acompanamiento',
                  onTap: () =>
                      setState(() => _selectedFilter = 'en_acompanamiento'),
                ),
                _FilterChip(
                  label: 'Finalizado',
                  selected: _selectedFilter == 'finalizado',
                  onTap: () => setState(() => _selectedFilter = 'finalizado'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SupervisedRequestsPanel(
            userId: userId,
            selectedFilter: _selectedFilter,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Supervisión',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/home_generador');
            return;
          }
          if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/categories-pro');
          }
        },
      ),
    );
  }
}

class _SupervisedRequestsPanel extends StatelessWidget {
  final String? userId;
  final String selectedFilter;

  const _SupervisedRequestsPanel({
    required this.userId,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null || Firebase.apps.isEmpty) {
      return _EmptySupervisionState(
        onCreate: () {
          Navigator.of(context).pushNamed(
            '/crear_solicitud',
            arguments: const {
              'supervisorType': 'prequote_diagnostic',
              'supervisorRequested': true,
            },
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .where('generadorId', isEqualTo: userId)
          .where('supervisorRequested', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final filteredDocs = docs.where((doc) {
          if (selectedFilter == 'todos') {
            return true;
          }
          final status =
              doc.data()['supervisorStatus']?.toString() ??
              'pendiente_asignacion';
          return status == selectedFilter;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _EmptySupervisionState(
            onCreate: () {
              Navigator.of(context).pushNamed(
                '/crear_solicitud',
                arguments: const {
                  'supervisorType': 'prequote_diagnostic',
                  'supervisorRequested': true,
                },
              );
            },
          );
        }

        final sorted = [...filteredDocs]
          ..sort((a, b) {
            final aCreated = a.data()['createdAt'];
            final bCreated = b.data()['createdAt'];
            final aTs = aCreated is Timestamp
                ? aCreated
                : Timestamp.fromMillisecondsSinceEpoch(0);
            final bTs = bCreated is Timestamp
                ? bCreated
                : Timestamp.fromMillisecondsSinceEpoch(0);
            return bTs.compareTo(aTs);
          });

        return Column(
          children: sorted.map((doc) {
            final data = doc.data();
            final supervisorType =
                data['supervisorType']?.toString() ?? 'prequote_diagnostic';
            final supervisorStatus =
                data['supervisorStatus']?.toString() ?? 'pendiente_asignacion';
            final supervisorCost =
                (data['supervisorCost'] as num?)?.toDouble() ?? 0;
            final qualityEvaluationRequired =
                data['providerQualityEvaluationRequired'] == true;
            final technicalSurveySheet = resolveTechnicalSurveySheet(data);
            final providerQualityEvaluation = resolveProviderQualityEvaluation(
              data,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SolicitudDetallePage(solicitudId: doc.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDCE7DF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniTag(
                              label: _mapSupervisorType(supervisorType),
                              background: const Color(0xFFE9F3ED),
                              foreground:
                                  SupervisionGeneradorPage._brandGreenSoft,
                            ),
                            _MiniTag(
                              label: _mapSupervisorStatus(supervisorStatus),
                              background: const Color(0xFFF2F4F7),
                              foreground: const Color(0xFF4E5968),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['titulo']?.toString() ??
                                    'Solicitud con supervisión',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['descripcion']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: data['city']?.toString() ?? 'Sin ciudad',
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          text: supervisorCost > 0
                              ? 'Costo supervisión: ${supervisorCost.toStringAsFixed(0)} COP'
                              : 'Costo por confirmar',
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          text:
                              'Atendido por personal técnico directo de SaneApp',
                        ),
                        if (technicalSurveySheet != null) ...[
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.fact_check_outlined,
                            text:
                                'Ficha técnica: ${mapTechnicalSheetStatusLabel(technicalSurveySheet['status']?.toString())}',
                          ),
                        ],
                        if (qualityEvaluationRequired) ...[
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.star_outline,
                            text: providerQualityEvaluation != null
                                ? 'Evaluación de calidad: ${mapQualityEvaluationStatusLabel(providerQualityEvaluation['status']?.toString())}'
                                : 'Incluye evaluación de calidad del proveedor durante la ejecución',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _mapSupervisorStatus(String status) {
    switch (status) {
      case 'asignado':
        return 'Supervisor asignado';
      case 'pendiente_asignacion':
        return 'Pendiente asignación';
      case 'en_acompanamiento':
        return 'En acompañamiento';
      case 'verificado':
        return 'Verificado';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Pendiente';
    }
  }

  String _mapSupervisorType(String type) {
    switch (type) {
      case 'execution_traceability':
      case 'completo':
        return 'Ejecución y calidad';
      case 'prequote_diagnostic':
      case 'puntual':
      default:
        return 'Preinspección técnica';
    }
  }
}

class _SupervisionModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SupervisionModeCard({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _MiniTag(
                          label: badgeLabel,
                          background: accentColor.withOpacity(0.12),
                          foreground: accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(backgroundColor: accentColor),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Solicitar esta modalidad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySupervisionState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptySupervisionState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aún no tienes servicios con supervisión',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando un trabajo requiera levantamiento técnico, acompañamiento en sitio o respaldo de cierre, puedes activarlo desde aquí y dejar trazabilidad completa para el proveedor y para tu operación.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: SupervisionGeneradorPage._brandGreen,
            ),
            icon: const Icon(Icons.add_task),
            label: const Text('Crear solicitud con supervisión'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFE7F4EB),
        labelStyle: TextStyle(
          color: selected
              ? SupervisionGeneradorPage._brandGreenSoft
              : const Color(0xFF4E5968),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SupervisionGeneradorPage._brandGreenSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}
