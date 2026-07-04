import 'package:flutter/material.dart';
import 'generator_profile_controller.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);

class GeneratorProfileSetupScreen extends StatefulWidget {
  const GeneratorProfileSetupScreen({super.key});

  @override
  State<GeneratorProfileSetupScreen> createState() =>
      _GeneratorProfileSetupScreenState();
}

class _GeneratorProfileSetupScreenState
    extends State<GeneratorProfileSetupScreen> {
  final controller = GeneratorProfileController();
  int step = 0;
  bool saving = false;
  bool completed = false;
  String? errorMsg;

  void nextStep() {
    setState(() {
      step++;
    });
  }

  void prevStep() {
    setState(() {
      step--;
    });
  }

  Future<void> finish() async {
    setState(() {
      saving = true;
      errorMsg = null;
    });
    try {
      await controller.saveProfile();
      setState(() {
        completed = true;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          title: const Text('Perfil Generador'),
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: _brandGreenSoft, size: 64),
              SizedBox(height: 16),
              Text(
                'Tu perfil fue configurado correctamente. Ahora puedes publicar solicitudes de servicio.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Configura tu perfil'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: step,
        onStepContinue: () {
          if (step == 0 && controller.isStep1Valid) {
            nextStep();
          } else if (step == 1 && controller.isStep2Valid)
            nextStep();
          else if (step == 2 && controller.isStep3Valid)
            nextStep();
          else if (step == 3 && controller.isStep4Valid)
            nextStep();
          else if (step == 4 && controller.isStep5Valid)
            finish();
        },
        onStepCancel: step > 0 ? prevStep : null,
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (step > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('AtrÃ¡s'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    (step == 0 && controller.isStep1Valid) ||
                        (step == 1 && controller.isStep2Valid) ||
                        (step == 2 && controller.isStep3Valid) ||
                        (step == 3 && controller.isStep4Valid) ||
                        (step == 4 && controller.isStep5Valid && !saving)
                    ? details.onStepContinue
                    : null,
                child: step == 4
                    ? (saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Finalizar'))
                    : const Text('Siguiente'),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('CategorÃ­as principales'),
            isActive: step >= 0,
            state: step > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Â¿QuÃ© tipo de servicios ambientales contratas con mayor frecuencia?',
                ),
                Wrap(
                  spacing: 8,
                  children: GeneratorProfileController.categoriesList.map((
                    cat,
                  ) {
                    final selected = controller.selectedCategories.contains(
                      cat,
                    );
                    return FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            controller.selectedCategories.add(cat);
                          } else {
                            controller.selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (!controller.isStep1Valid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecciona al menos una categorÃ­a.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('SubcategorÃ­as'),
            isActive: step >= 1,
            state: step > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona las subcategorÃ­as que aplican a tu operaciÃ³n.',
                ),
                ...controller.selectedCategories.expand((cat) {
                  final subs =
                      GeneratorProfileController.subcategoriesMap[cat] ?? [];
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        cat,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: subs.map((sub) {
                        final selected = controller.selectedSubcategories
                            .contains(sub);
                        return FilterChip(
                          label: Text(sub),
                          selected: selected,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                controller.selectedSubcategories.add(sub);
                              } else {
                                controller.selectedSubcategories.remove(sub);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ];
                }),
                if (!controller.isStep2Valid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecciona al menos una subcategorÃ­a.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Frecuencia de contrataciÃ³n'),
            isActive: step >= 2,
            state: step > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Â¿Con quÃ© frecuencia contratas estos servicios?'),
                ...GeneratorProfileController.contractFrequencies.map(
                  (freq) => RadioListTile<String>(
                    title: Text(freq),
                    value: freq,
                    groupValue: controller.contractFrequency,
                    onChanged: (v) =>
                        setState(() => controller.contractFrequency = v),
                  ),
                ),
                if (!controller.isStep3Valid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecciona una frecuencia.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Presupuesto promedio'),
            isActive: step >= 3,
            state: step > 3 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Â¿CuÃ¡l es tu rango de contrataciÃ³n por servicio?',
                ),
                ...GeneratorProfileController.budgetRanges.map(
                  (range) => RadioListTile<String>(
                    title: Text(range),
                    value: range,
                    groupValue: controller.budgetRange,
                    onChanged: (v) =>
                        setState(() => controller.budgetRange = v),
                  ),
                ),
                if (!controller.isStep4Valid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecciona un rango de presupuesto.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Cobertura geogrÃ¡fica'),
            isActive: step >= 4,
            state: step == 4 && controller.isStep5Valid
                ? StepState.complete
                : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Â¿En quÃ© ciudades necesitas servicio?'),
                ...GeneratorProfileController.coverages.map(
                  (cov) => RadioListTile<String>(
                    title: Text(cov),
                    value: cov,
                    groupValue: controller.coverage,
                    onChanged: (v) => setState(() => controller.coverage = v),
                  ),
                ),
                if (!controller.isStep5Valid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecciona una cobertura.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
