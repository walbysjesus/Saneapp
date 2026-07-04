import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Map<String, dynamic> buildInitialTechnicalSurveySheet({
  String? city,
  String? address,
  String? serviceCategory,
  String? urgency,
}) {
  return {
    'status': 'pendiente_levantamiento',
    'serviceCity': city,
    'serviceAddress': address,
    'serviceCategory': serviceCategory,
    'urgency': urgency,
    'siteAccess': 'Pendiente de verificación en sitio por SaneApp.',
    'residueProfile': 'Clasificación preliminar pendiente durante la visita.',
    'operationalRisks':
        'Sin hallazgos aún. Se validarán accesos, maniobras y condiciones del punto.',
    'requiredEquipment': 'Por definir con el levantamiento técnico.',
    'photoEvidenceUrls': const <String>[],
    'photoEvidenceCount': 0,
    'recommendations':
        'SaneApp emitirá recomendaciones y alcance sugerido cuando cierre la visita.',
    'providerGuidance':
        'La ficha técnica quedará visible para soportar la cotización del proveedor.',
  };
}

Map<String, dynamic> buildInitialProviderQualityEvaluation() {
  return {
    'status': 'pendiente',
    'goodPracticesScore': null,
    'punctualityScore': null,
    'executionQualityScore': null,
    'communicationScore': null,
    'incidentCount': 0,
    'incidentNotes': const <String>[],
    'evidenceUrls': const <String>[],
    'evidenceCount': 0,
    'improvementActions': 'Pendiente de supervisión durante la ejecución.',
    'closureSummary':
        'La evaluación se emitirá cuando SaneApp cierre el acompañamiento.',
  };
}

Map<String, dynamic>? resolveTechnicalSurveySheet(
  Map<String, dynamic> requestData,
) {
  final raw = requestData['technicalSurveySheet'];
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  if (requestData['prequoteTechnicalSurveyRequired'] == true) {
    return buildInitialTechnicalSurveySheet(
      city: requestData['city']?.toString(),
      address: requestData['operationAddress']?.toString(),
      serviceCategory: requestData['serviceInterest']?.toString(),
      urgency: requestData['serviceUrgency']?.toString(),
    );
  }
  return null;
}

Map<String, dynamic>? resolveProviderQualityEvaluation(
  Map<String, dynamic> requestData,
) {
  final raw = requestData['providerQualityEvaluation'];
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  if (requestData['providerQualityEvaluationRequired'] == true) {
    return buildInitialProviderQualityEvaluation();
  }
  return null;
}

Map<String, dynamic>? resolveSupervisorActa(
  Map<String, dynamic> requestData, {
  required bool finalActa,
}) {
  final raw = requestData[finalActa ? 'actaFinal' : 'actaInicial'];
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return null;
}

Map<String, dynamic>? resolveSupervisorVisitLocation(
  Map<String, dynamic> requestData,
) {
  final raw = requestData['lastSupervisorVisitLocation'];
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  final finalActa = resolveSupervisorActa(requestData, finalActa: true);
  final initialActa = resolveSupervisorActa(requestData, finalActa: false);
  final finalLocation = finalActa?['visitLocation'];
  if (finalLocation is Map) {
    return Map<String, dynamic>.from(finalLocation);
  }
  final initialLocation = initialActa?['visitLocation'];
  if (initialLocation is Map) {
    return Map<String, dynamic>.from(initialLocation);
  }
  return null;
}

List<String> resolveSupervisionLogEntries(Map<String, dynamic> requestData) {
  return (requestData['supervisionLogEntries'] as List?)
          ?.map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList() ??
      <String>[];
}

List<String> resolveSupervisorEvidenceUrls(Map<String, dynamic> requestData) {
  final urls = <String>{};
  final initialActa = resolveSupervisorActa(requestData, finalActa: false);
  final finalActa = resolveSupervisorActa(requestData, finalActa: true);
  final technicalSheet = resolveTechnicalSurveySheet(requestData);
  final qualityEvaluation = resolveProviderQualityEvaluation(requestData);

  urls.addAll(
    (initialActa?['listaImagenesUrls'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty) ??
        const <String>[],
  );
  urls.addAll(
    (finalActa?['imagenesFinales'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty) ??
        const <String>[],
  );
  urls.addAll(
    (technicalSheet?['photoEvidenceUrls'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty) ??
        const <String>[],
  );
  urls.addAll(
    (qualityEvaluation?['evidenceUrls'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty) ??
        const <String>[],
  );
  return urls.toList();
}

String mapTechnicalSheetStatusLabel(String? status) {
  switch (status) {
    case 'en_levantamiento':
      return 'Levantamiento en curso';
    case 'emitida':
      return 'Ficha emitida';
    case 'compartida_con_proveedor':
      return 'Compartida con proveedor';
    default:
      return 'Pendiente de visita';
  }
}

String mapQualityEvaluationStatusLabel(String? status) {
  switch (status) {
    case 'en_revision':
      return 'En revisión';
    case 'emitida':
      return 'Evaluación emitida';
    case 'socializada':
      return 'Socializada';
    default:
      return 'Pendiente';
  }
}

class TechnicalSurveySheetCard extends StatelessWidget {
  final Map<String, dynamic>? sheet;
  final bool providerFacing;
  final String title;

  const TechnicalSurveySheetCard({
    super.key,
    required this.sheet,
    this.providerFacing = false,
    this.title = 'Ficha técnica previa a cotización',
  });

  @override
  Widget build(BuildContext context) {
    final data = sheet;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final photoCount = (data['photoEvidenceCount'] as num?)?.toInt() ?? 0;

    return _ArtifactCard(
      title: title,
      statusLabel: mapTechnicalSheetStatusLabel(data['status']?.toString()),
      accentColor: const Color(0xFF1E7A4B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerFacing
                ? 'Este levantamiento lo comparte SaneApp para que cotices con condiciones operativas más claras.'
                : 'Resume lo que SaneApp debe levantar antes de enviar o afinar cotizaciones del proveedor.',
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 12),
          _ArtifactInfoRow(
            label: 'Accesos',
            value: data['siteAccess']?.toString() ?? '-',
          ),
          _ArtifactInfoRow(
            label: 'Residuos',
            value: data['residueProfile']?.toString() ?? '-',
          ),
          _ArtifactInfoRow(
            label: 'Riesgos',
            value: data['operationalRisks']?.toString() ?? '-',
          ),
          _ArtifactInfoRow(
            label: 'Equipos',
            value: data['requiredEquipment']?.toString() ?? '-',
          ),
          _ArtifactInfoRow(
            label: 'Fotografías',
            value: '$photoCount evidencia(s) cargadas',
          ),
          _ArtifactInfoRow(
            label: 'Recomendación',
            value: data['recommendations']?.toString() ?? '-',
          ),
          _ArtifactInfoRow(
            label: 'Uso para proveedor',
            value: data['providerGuidance']?.toString() ?? '-',
          ),
        ],
      ),
    );
  }
}

class ProviderQualityEvaluationCard extends StatelessWidget {
  final Map<String, dynamic>? evaluation;
  final bool providerFacing;
  final String title;

  const ProviderQualityEvaluationCard({
    super.key,
    required this.evaluation,
    this.providerFacing = false,
    this.title = 'Evaluación de calidad del proveedor',
  });

  @override
  Widget build(BuildContext context) {
    final data = evaluation;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final goodPracticesScore = (data['goodPracticesScore'] as num?)?.toInt();
    final punctualityScore = (data['punctualityScore'] as num?)?.toInt();
    final executionQualityScore = (data['executionQualityScore'] as num?)
        ?.toInt();
    final communicationScore = (data['communicationScore'] as num?)?.toInt();
    final overallScore = (data['overallScore'] as num?)?.toInt();
    final concept = data['concept']?.toString();
    final recommendation = data['recommendation']?.toString();
    final evidenceCount = (data['evidenceCount'] as num?)?.toInt() ?? 0;
    final incidentCount = (data['incidentCount'] as num?)?.toInt() ?? 0;

    return _ArtifactCard(
      title: title,
      statusLabel: mapQualityEvaluationStatusLabel(data['status']?.toString()),
      accentColor: const Color(0xFFC24E00),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerFacing
                ? 'SaneApp usa esta evaluación para dejar trazabilidad sobre buenas prácticas, calidad de ejecución e incidencias del servicio.'
                : 'Mide el desempeño del proveedor elegido durante la ejecución acompañada por SaneApp.',
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (overallScore != null)
                _ScoreChip(label: 'Resultado total', score: overallScore, outOf: 100),
              _ScoreChip(label: 'Buenas prácticas', score: goodPracticesScore),
              _ScoreChip(label: 'Puntualidad', score: punctualityScore),
              _ScoreChip(
                label: 'Calidad técnica',
                score: executionQualityScore,
              ),
              _ScoreChip(label: 'Comunicación', score: communicationScore),
            ],
          ),
          const SizedBox(height: 12),
          _ArtifactInfoRow(
            label: 'Evidencias',
            value: '$evidenceCount evidencia(s) registradas',
          ),
          _ArtifactInfoRow(
            label: 'Incidencias',
            value: incidentCount > 0
                ? '$incidentCount incidencia(s) documentadas'
                : 'Sin incidencias documentadas por ahora',
          ),
          _ArtifactInfoRow(
            label: 'Acciones',
            value: data['improvementActions']?.toString() ?? '-',
          ),
          if (concept != null && concept.isNotEmpty)
            _ArtifactInfoRow(label: 'Concepto', value: concept),
          if (recommendation != null && recommendation.isNotEmpty)
            _ArtifactInfoRow(label: 'Recomendación', value: recommendation),
          _ArtifactInfoRow(
            label: 'Cierre',
            value: data['closureSummary']?.toString() ?? '-',
          ),
        ],
      ),
    );
  }
}

class SupervisorSupportCard extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final bool providerFacing;
  final String title;

  const SupervisorSupportCard({
    super.key,
    required this.requestData,
    this.providerFacing = false,
    this.title = 'Soporte de supervisión en campo',
  });

  @override
  Widget build(BuildContext context) {
    final initialActa = resolveSupervisorActa(requestData, finalActa: false);
    final finalActa = resolveSupervisorActa(requestData, finalActa: true);
    final visitLocation = resolveSupervisorVisitLocation(requestData);
    final logEntries = resolveSupervisionLogEntries(requestData);
    final evidenceUrls = resolveSupervisorEvidenceUrls(requestData);

    if (initialActa == null &&
        finalActa == null &&
        visitLocation == null &&
        logEntries.isEmpty &&
        evidenceUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ArtifactCard(
      title: title,
      statusLabel: _mapSupervisorSupportStatus(requestData['supervisorStatus']?.toString()),
      accentColor: const Color(0xFF0C4F31),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerFacing
                ? 'Esta trazabilidad te ayuda a preparar tu propuesta y ejecutar con un contexto real del sitio, la visita y las incidencias observadas por SaneApp.'
                : 'Consolida las actas, la georreferencia, la bitácora y la evidencia que SaneApp levantó durante la supervisión de campo.',
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (initialActa != null) _ActaSummaryCard(title: 'Acta inicial', data: initialActa, finalActa: false),
          if (initialActa != null && finalActa != null) const SizedBox(height: 10),
          if (finalActa != null) _ActaSummaryCard(title: 'Acta final', data: finalActa, finalActa: true),
          if (visitLocation != null) ...[
            const SizedBox(height: 12),
            _ArtifactInfoRow(
              label: 'Último GPS',
              value: _formatLocation(visitLocation),
            ),
          ],
          if (logEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Bitácora de campo',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...logEntries.take(4).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 8, color: Color(0xFF1E7A4B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry,
                        style: const TextStyle(color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (logEntries.length > 4)
              Text(
                '+${logEntries.length - 4} registro(s) adicionales',
                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
              ),
          ],
          if (evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ArtifactInfoRow(
              label: 'Evidencias',
              value: '${evidenceUrls.length} archivo(s) compartidos',
            ),
            const SizedBox(height: 8),
            _RemoteEvidencePreviewGrid(urls: evidenceUrls),
          ],
        ],
      ),
    );
  }

  String _formatLocation(Map<String, dynamic> location) {
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    final accuracy = location['accuracy'];
    return 'Lat $latitude, Lng $longitude, precisión ${accuracy ?? '-'} m';
  }
}

class _ArtifactCard extends StatelessWidget {
  final String title;
  final String statusLabel;
  final Color accentColor;
  final Widget child;

  const _ArtifactCard({
    required this.title,
    required this.statusLabel,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ArtifactInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ArtifactInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int? score;
  final int outOf;

  const _ScoreChip({
    required this.label,
    required this.score,
    this.outOf = 5,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedScore = score;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBE5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resolvedScore == null ? 'Pendiente' : '$resolvedScore/$outOf',
            style: TextStyle(
              color: resolvedScore == null
                  ? const Color(0xFF6B7280)
                  : const Color(0xFFC24E00),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActaSummaryCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final bool finalActa;

  const _ActaSummaryCard({
    required this.title,
    required this.data,
    required this.finalActa,
  });

  @override
  Widget build(BuildContext context) {
    final notes = finalActa
        ? data['observacionesFinales']?.toString()
        : data['observaciones']?.toString();
    final evidence = (finalActa ? data['imagenesFinales'] : data['listaImagenesUrls']) as List?;
    final evidenceCount = evidence?.length ?? 0;
    final verification = finalActa
        ? (data['cumplimientoServicio'] == true ? 'Cumplimiento verificado' : 'Cumplimiento no confirmado')
        : (data['condicionesInicialesVerificadas'] == true ? 'Condiciones verificadas' : 'Condiciones pendientes');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _ArtifactInfoRow(label: 'Fecha', value: data['fecha']?.toString() ?? '-'),
          _ArtifactInfoRow(label: 'Resultado', value: verification),
          _ArtifactInfoRow(label: 'Evidencia', value: '$evidenceCount archivo(s)'),
          _ArtifactInfoRow(label: 'Observaciones', value: notes == null || notes.isEmpty ? '-' : notes),
        ],
      ),
    );
  }
}

class _RemoteEvidencePreviewGrid extends StatelessWidget {
  final List<String> urls;

  const _RemoteEvidencePreviewGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.take(6).map((url) => _RemoteEvidenceTile(url: url)).toList(),
    );
  }
}

class _RemoteEvidenceTile extends StatelessWidget {
  final String url;

  const _RemoteEvidenceTile({required this.url});

  @override
  Widget build(BuildContext context) {
    final imageLike = _isImageUrl(url);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openEvidence(context, imageLike: imageLike),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 88,
          height: 88,
          color: const Color(0xFFF1F5F2),
          child: imageLike
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _EvidenceFallbackTile(),
                )
              : const _EvidenceFallbackTile(),
        ),
      ),
    );
  }

  bool _isImageUrl(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('.jpg') ||
        normalized.contains('.jpeg') ||
        normalized.contains('.png') ||
        normalized.contains('.webp');
  }

  Future<void> _openEvidence(BuildContext context, {required bool imageLike}) async {
    if (!imageLike) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 720),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Evidencia de supervisión',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const _EvidenceFallbackTile(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('Abrir archivo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EvidenceFallbackTile extends StatelessWidget {
  const _EvidenceFallbackTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.insert_drive_file_outlined, color: Colors.black45),
    );
  }
}

String _mapSupervisorSupportStatus(String? status) {
  switch (status) {
    case 'pendiente_verificacion':
      return 'Verificación pendiente';
    case 'verificado':
      return 'Verificación completada';
    case 'en_acompanamiento':
      return 'Acompañamiento';
    case 'finalizado':
      return 'Cierre operativo';
    default:
      return 'Soporte disponible';
  }
}
