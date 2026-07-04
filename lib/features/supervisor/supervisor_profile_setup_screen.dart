import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../state/app_state.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);

class SupervisorProfileSetupScreen extends StatefulWidget {
  const SupervisorProfileSetupScreen({super.key});

  @override
  State<SupervisorProfileSetupScreen> createState() =>
      _SupervisorProfileSetupScreenState();
}

class _SupervisorProfileSetupScreenState
    extends State<SupervisorProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _educationController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _lastEmployerController = TextEditingController();
  final _strengthsController = TextEditingController();
  final _restrictionsController = TextEditingController();

  String? _mobilityAvailability;
  String? _shiftAvailability;
  String? _travelAvailability;
  bool _canLiftWeight = false;
  bool _canUsePpe = false;
  bool _canStandLongHours = false;
  bool _canWorkOutdoors = false;
  bool _acceptsFieldWork = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, int> _answers = {};

  static const int _passingScore = 90;
  static const int _minimumExperienceYears = 5;
  static const int _minimumEducationLength = 12;
  static const int _minimumCertificationsLength = 15;
  static const int _minimumReferenceLength = 8;
  static const int _minimumPhoneLength = 10;

  final List<_AssessmentQuestion> _questions = const [
    _AssessmentQuestion(
      id: 'waste_classification',
      prompt:
          '¿Cuál es la primera acción correcta ante un residuo de origen desconocido durante una inspección?',
      options: [
        _AssessmentOption(
          text: 'Trasladarlo de inmediato al área común',
          points: 0,
        ),
        _AssessmentOption(
          text: 'Clasificarlo visualmente sin evidencia',
          points: 0,
        ),
        _AssessmentOption(
          text:
              'Aislarlo, registrar evidencia y activar protocolo de identificación',
          points: 20,
        ),
      ],
    ),
    _AssessmentQuestion(
      id: 'ppe',
      prompt:
          'Antes de ingresar a una operación con riesgo químico, ¿qué debe validar el supervisor?',
      options: [
        _AssessmentOption(
          text: 'Solo la hora de llegada del proveedor',
          points: 0,
        ),
        _AssessmentOption(
          text: 'EPP, permisos, condiciones del área y plan de contingencia',
          points: 20,
        ),
        _AssessmentOption(
          text: 'Que el cliente haya firmado la orden de servicio',
          points: 0,
        ),
      ],
    ),
    _AssessmentQuestion(
      id: 'incident_reporting',
      prompt:
          'Si ocurre un incidente en campo sin lesionados, el supervisor debe:',
      options: [
        _AssessmentOption(
          text: 'Esperar al final del día para reportarlo',
          points: 0,
        ),
        _AssessmentOption(
          text: 'Documentarlo, escalarlo y dejar trazabilidad inmediata',
          points: 20,
        ),
        _AssessmentOption(text: 'Resolverlo verbalmente sin acta', points: 0),
      ],
    ),
    _AssessmentQuestion(
      id: 'traceability',
      prompt:
          '¿Qué evidencia mínima debe quedar en una supervisión operativa cerrada correctamente?',
      options: [
        _AssessmentOption(
          text: 'Solo una foto del frente del sitio',
          points: 0,
        ),
        _AssessmentOption(
          text: 'Acta, evidencias, hallazgos, responsables y hora de cierre',
          points: 20,
        ),
        _AssessmentOption(
          text: 'Mensaje de chat interno entre supervisor y proveedor',
          points: 0,
        ),
      ],
    ),
    _AssessmentQuestion(
      id: 'decision_criteria',
      prompt:
          'Cuando detecta una condición insegura crítica durante la ejecución, el supervisor debe:',
      options: [
        _AssessmentOption(
          text: 'Permitir continuar mientras registra el hallazgo',
          points: 0,
        ),
        _AssessmentOption(
          text: 'Detener la actividad, asegurar el área y activar escalamiento',
          points: 20,
        ),
        _AssessmentOption(
          text: 'Pedir autorización al proveedor antes de actuar',
          points: 0,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emergencyContactController.dispose();
    _experienceYearsController.dispose();
    _educationController.dispose();
    _certificationsController.dispose();
    _lastEmployerController.dispose();
    _strengthsController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final fallbackUser = appState.currentUser;
      final firebaseReady = Firebase.apps.isNotEmpty;
      final firebaseUser = firebaseReady
          ? FirebaseAuth.instance.currentUser
          : null;
      final userId = firebaseUser?.uid ?? fallbackUser?.uid;
      final userName =
          firebaseUser?.displayName ?? fallbackUser?.fullName ?? '';

      if (userId == null) {
        setState(() {
          _errorMessage = 'Usuario no autenticado.';
          _isLoading = false;
        });
        return;
      }

      final data = <String, dynamic>{
        'fullName': fallbackUser?.fullName,
        'city': fallbackUser?.city,
        'status': fallbackUser?.status,
        'supervisorProfileCompleted': fallbackUser?.supervisorProfileCompleted,
        'supervisorAssessmentPassed': fallbackUser?.supervisorAssessmentPassed,
        'supervisorAssessmentScore': fallbackUser?.supervisorAssessmentScore,
      };

      if (firebaseReady) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        data.addAll(snapshot.data() ?? <String, dynamic>{});
      }

      _fullNameController.text = data['fullName'] as String? ?? userName;
      _phoneController.text = data['supervisorPhone'] as String? ?? '';
      _cityController.text = data['city'] as String? ?? '';
      _emergencyContactController.text =
          data['supervisorEmergencyContact'] as String? ?? '';
      _experienceYearsController.text =
          (data['supervisorExperienceYears'] as num?)?.toString() ?? '';
      _educationController.text = data['supervisorEducation'] as String? ?? '';
      _certificationsController.text =
          data['supervisorCertifications'] as String? ?? '';
      _lastEmployerController.text =
          data['supervisorLastEmployer'] as String? ?? '';
      _strengthsController.text =
          data['supervisorOperationalStrengths'] as String? ?? '';
      _restrictionsController.text =
          data['supervisorOperationalRestrictions'] as String? ?? '';
      _mobilityAvailability = data['supervisorMobilityAvailability'] as String?;
      _shiftAvailability = data['supervisorShiftAvailability'] as String?;
      _travelAvailability = data['supervisorTravelAvailability'] as String?;
      _canLiftWeight = data['supervisorCanLiftWeight'] == true;
      _canUsePpe = data['supervisorCanUsePpe'] == true;
      _canStandLongHours = data['supervisorCanStandLongHours'] == true;
      _canWorkOutdoors = data['supervisorCanWorkOutdoors'] == true;
      _acceptsFieldWork = data['supervisorAcceptsFieldWork'] == true;
      final answers =
          data['supervisorAssessmentAnswers'] as Map<String, dynamic>?;
      if (answers != null) {
        for (final entry in answers.entries) {
          _answers[entry.key] = (entry.value as num).toInt();
        }
      }
    } catch (error) {
      _errorMessage = 'No se pudo cargar el borrador del supervisor.';
      debugPrint('Supervisor draft load failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int get _assessmentScore =>
      _answers.values.fold<int>(0, (total, value) => total + value);

  _SupervisorAutoReviewResult _buildAutoReviewResult({required int score}) {
    final reasons = <String>[];
    var passedChecks = 0;
    const totalChecks = 8;

    final experienceYears =
        int.tryParse(_experienceYearsController.text.trim()) ?? 0;
    final phone = _phoneController.text.trim();
    final emergencyContact = _emergencyContactController.text.trim();
    final education = _educationController.text.trim();
    final certifications = _certificationsController.text.trim();
    final lastEmployer = _lastEmployerController.text.trim();

    if (score >= _passingScore) {
      passedChecks++;
    } else {
      reasons.add('El puntaje técnico mínimo requerido es $_passingScore/100.');
    }

    if (experienceYears >= _minimumExperienceYears) {
      passedChecks++;
    } else {
      reasons.add(
        'Se requieren al menos $_minimumExperienceYears años de experiencia operativa comprobable.',
      );
    }

    if (education.length >= _minimumEducationLength) {
      passedChecks++;
    } else {
      reasons.add(
        'Debes registrar una formación técnica o profesional verificable y suficientemente detallada.',
      );
    }

    if (certifications.length >= _minimumCertificationsLength) {
      passedChecks++;
    } else {
      reasons.add(
        'Debes informar certificaciones o cursos vigentes relacionados con seguridad y operación.',
      );
    }

    if (lastEmployer.length >= _minimumReferenceLength) {
      passedChecks++;
    } else {
      reasons.add(
        'Debes indicar tu último empleador o una referencia operativa reciente con suficiente detalle.',
      );
    }

    if (phone.length >= _minimumPhoneLength &&
        emergencyContact.length >= _minimumPhoneLength) {
      passedChecks++;
    } else {
      reasons.add(
        'Debes registrar teléfono principal y contacto de emergencia válidos con al menos $_minimumPhoneLength dígitos.',
      );
    }

    final hasAvailability =
        _mobilityAvailability != null &&
        _mobilityAvailability != 'Cobertura local únicamente' &&
        _shiftAvailability != null &&
        (_shiftAvailability == 'Rotativo' ||
            _shiftAvailability == 'Disponibilidad 24/7') &&
        _travelAvailability != null &&
        _travelAvailability != 'Sin viajes';
    if (hasAvailability) {
      passedChecks++;
    } else {
      reasons.add(
        'Debes contar con movilidad no limitada, turnos rotativos o 24/7 y disponibilidad para viajar.',
      );
    }

    final hasOperationalReadiness =
        _canLiftWeight &&
        _canUsePpe &&
        _canStandLongHours &&
        _canWorkOutdoors &&
        _acceptsFieldWork;
    if (hasOperationalReadiness) {
      passedChecks++;
    } else {
      reasons.add(
        'Debes confirmar carga operativa, EPP, permanencia prolongada, trabajo exterior y aceptación total de campo.',
      );
    }

    final eligibilityScore = ((passedChecks / totalChecks) * 100).round();
    final status = reasons.isEmpty ? 'prequalified' : 'requires_review';
    final summary = reasons.isEmpty
        ? 'Tu perfil superó el filtro automático objetivo y quedó precalificado.'
        : 'Tu perfil requiere validación adicional porque no cumple todos los criterios automáticos.';

    return _SupervisorAutoReviewResult(
      status: status,
      eligibilityScore: eligibilityScore,
      passedChecks: passedChecks,
      totalChecks: totalChecks,
      reasons: reasons,
      summary: summary,
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final allQuestionsAnswered = _questions.every(
      (question) => _answers.containsKey(question.id),
    );

    if (!isValid || !allQuestionsAnswered || !_acceptsFieldWork) {
      setState(() {
        _errorMessage = !allQuestionsAnswered
            ? 'Debes responder toda la evaluación técnica.'
            : !_acceptsFieldWork
            ? 'Debes confirmar disponibilidad para trabajo 100% operativo.'
            : 'Completa todos los campos obligatorios.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Usuario no autenticado.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final score = _assessmentScore;
    final passed = score >= _passingScore;
    final autoReview = _buildAutoReviewResult(score: score);
    final payload = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'city': _cityController.text.trim(),
      'supervisorPhone': _phoneController.text.trim(),
      'supervisorEmergencyContact': _emergencyContactController.text.trim(),
      'supervisorExperienceYears':
          int.tryParse(_experienceYearsController.text.trim()) ?? 0,
      'supervisorEducation': _educationController.text.trim(),
      'supervisorCertifications': _certificationsController.text.trim(),
      'supervisorLastEmployer': _lastEmployerController.text.trim(),
      'supervisorOperationalStrengths': _strengthsController.text.trim(),
      'supervisorOperationalRestrictions': _restrictionsController.text.trim(),
      'supervisorMobilityAvailability': _mobilityAvailability,
      'supervisorShiftAvailability': _shiftAvailability,
      'supervisorTravelAvailability': _travelAvailability,
      'supervisorCanLiftWeight': _canLiftWeight,
      'supervisorCanUsePpe': _canUsePpe,
      'supervisorCanStandLongHours': _canStandLongHours,
      'supervisorCanWorkOutdoors': _canWorkOutdoors,
      'supervisorAcceptsFieldWork': _acceptsFieldWork,
      'supervisorAssessmentAnswers': _answers,
      'supervisorAssessmentScore': score,
      'supervisorAssessmentPassed': passed,
      'supervisorEligibilityScore': autoReview.eligibilityScore,
      'supervisorEligibilityPassedChecks': autoReview.passedChecks,
      'supervisorEligibilityTotalChecks': autoReview.totalChecks,
      'supervisorEligibilityReasons': autoReview.reasons,
      'supervisorEligibilitySummary': autoReview.summary,
      'supervisorAutoReviewVersion': 1,
      'supervisorAutoReviewedAt': FieldValue.serverTimestamp(),
      'supervisorProfileCompleted': true,
      'status': autoReview.status,
      'supervisorDecision': FieldValue.delete(),
      'supervisorReviewedAt': FieldValue.delete(),
      'supervisorReviewedBy': FieldValue.delete(),
      'supervisorRejectionReason': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));
      if (!mounted) {
        return;
      }
      Provider.of<AppState>(context, listen: false).setUser(
        UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: _fullNameController.text.trim(),
          role: 'supervisor',
          city: _cityController.text.trim(),
          status: autoReview.status,
          supervisorProfileCompleted: true,
          supervisorAssessmentPassed: passed,
          supervisorAssessmentScore: score,
        ),
        UserRole.supervisor,
      );
      Navigator.pushReplacementNamed(context, '/supervisor-application-status');
    } on FirebaseException catch (error) {
      final message = switch (error.code) {
        'permission-denied' =>
          'Firebase rechazó la actualización del perfil del supervisor. Debes publicar las reglas nuevas de Firestore.',
        'unavailable' =>
          'No fue posible conectar con Firebase para enviar la postulación.',
        _ => 'No se pudo enviar la postulación del supervisor: ${error.message ?? error.code}',
      };
      setState(() {
        _errorMessage = message;
      });
      debugPrint('Supervisor submit failed [${error.code}]: ${error.message}');
    } catch (error) {
      setState(() {
        _errorMessage = 'No se pudo enviar la postulación del supervisor.';
      });
      debugPrint('Supervisor submit failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Registro operativo de supervisor'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [_brandGreen, _brandGreenSoft],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfil interno de supervisión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Este registro aplica un filtro automático estricto sobre experiencia, disponibilidad, aptitud física y criterio técnico antes de clasificar tu postulación.',
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Perfil interno de supervisión de campo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este registro aplica criterios estrictos de experiencia, formación, disponibilidad física y criterio técnico antes de habilitar el panel de supervisión.',
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Datos personales y de operación',
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Nombre completo',
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _cityController,
                        label: 'Ciudad base',
                      ),
                      _buildTextField(
                        controller: _emergencyContactController,
                        label: 'Contacto de emergencia',
                      ),
                      _buildTextField(
                        controller: _experienceYearsController,
                        label: 'Años de experiencia en supervisión operativa',
                        keyboardType: TextInputType.number,
                      ),
                      _buildDropdown(
                        label: 'Disponibilidad para movilidad',
                        value: _mobilityAvailability,
                        items: const [
                          'Moto o vehículo propio',
                          'Transporte público',
                          'Cobertura local únicamente',
                          'Cobertura regional',
                        ],
                        onChanged: (value) => setState(() {
                          _mobilityAvailability = value;
                        }),
                      ),
                      _buildDropdown(
                        label: 'Disponibilidad de turnos',
                        value: _shiftAvailability,
                        items: const [
                          'Diurno',
                          'Nocturno',
                          'Rotativo',
                          'Disponibilidad 24/7',
                        ],
                        onChanged: (value) => setState(() {
                          _shiftAvailability = value;
                        }),
                      ),
                      _buildDropdown(
                        label: 'Disponibilidad para viajar',
                        value: _travelAvailability,
                        items: const [
                          'Sin viajes',
                          'Viajes ocasionales',
                          'Viajes frecuentes',
                        ],
                        onChanged: (value) => setState(() {
                          _travelAvailability = value;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Formación y experiencia técnica',
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _educationController,
                        label: 'Estudios y formación principal',
                        maxLines: 2,
                      ),
                      _buildTextField(
                        controller: _certificationsController,
                        label: 'Certificaciones relevantes',
                        maxLines: 3,
                      ),
                      _buildTextField(
                        controller: _lastEmployerController,
                        label: 'Último empleador o contrato relevante',
                      ),
                      _buildTextField(
                        controller: _strengthsController,
                        label: 'Fortalezas operativas',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Capacidad física y disponibilidad de campo',
                  child: Column(
                    children: [
                      _CapabilityTile(
                        title:
                            'Puede manipular EPP y trabajar bajo protocolos SST',
                        value: _canUsePpe,
                        onChanged: (value) => setState(() {
                          _canUsePpe = value;
                        }),
                      ),
                      _CapabilityTile(
                        title:
                            'Puede permanecer de pie y caminar en campo varias horas',
                        value: _canStandLongHours,
                        onChanged: (value) => setState(() {
                          _canStandLongHours = value;
                        }),
                      ),
                      _CapabilityTile(
                        title:
                            'Puede trabajar en exteriores y condiciones operativas variables',
                        value: _canWorkOutdoors,
                        onChanged: (value) => setState(() {
                          _canWorkOutdoors = value;
                        }),
                      ),
                      _CapabilityTile(
                        title: 'Puede manipular cargas operativas moderadas',
                        value: _canLiftWeight,
                        onChanged: (value) => setState(() {
                          _canLiftWeight = value;
                        }),
                      ),
                      _CapabilityTile(
                        title: 'Acepta un cargo 100% operativo en campo',
                        value: _acceptsFieldWork,
                        onChanged: (value) => setState(() {
                          _acceptsFieldWork = value;
                        }),
                      ),
                      _buildTextField(
                        controller: _restrictionsController,
                        label: 'Restricciones operativas o recomendaciones',
                        maxLines: 3,
                        required: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Evaluación técnica del oficio',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Esta evaluación mide criterio operativo, seguridad, trazabilidad y toma de decisiones en campo.',
                      ),
                      const SizedBox(height: 16),
                      ..._questions.map(_buildQuestionCard),
                      const SizedBox(height: 8),
                      Text(
                        'Puntaje actual: $_assessmentScore/100. Puntaje mínimo exigido: $_passingScore/100. Experiencia mínima: $_minimumExperienceYears años. Turno requerido: rotativo o 24/7.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enviar postulación a revisión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(_AssessmentQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...question.options.map(
            (option) => RadioListTile<int>(
              value: option.points,
              groupValue: _answers[question.id],
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(option.text),
              onChanged: (value) => setState(() {
                if (value != null) {
                  _answers[question.id] = value;
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obligatorio';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged,
        validator: (selected) {
          if (selected == null || selected.isEmpty) {
            return 'Campo obligatorio';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CapabilityTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: Text(title),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _AssessmentQuestion {
  final String id;
  final String prompt;
  final List<_AssessmentOption> options;

  const _AssessmentQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });
}

class _AssessmentOption {
  final String text;
  final int points;

  const _AssessmentOption({required this.text, required this.points});
}

class _SupervisorAutoReviewResult {
  final String status;
  final int eligibilityScore;
  final int passedChecks;
  final int totalChecks;
  final List<String> reasons;
  final String summary;

  const _SupervisorAutoReviewResult({
    required this.status,
    required this.eligibilityScore,
    required this.passedChecks,
    required this.totalChecks,
    required this.reasons,
    required this.summary,
  });
}
