import 'package:flutter/material.dart';

class ServiceChatbotWidget extends StatefulWidget {
  final void Function(String fullDescription) onComplete;
  const ServiceChatbotWidget({super.key, required this.onComplete});

  @override
  State<ServiceChatbotWidget> createState() => _ServiceChatbotWidgetState();
}

class _ServiceChatbotWidgetState extends State<ServiceChatbotWidget> {
  int _step = 0;
  final Map<String, String> _answers = {};
  final _controller = TextEditingController();
  bool _completed = false;

  final List<Map<String, String>> _questions = [
    {
      'key': 'tipo',
      'q': 'Â¿QuÃ© tipo de servicio necesitas? (ej: residuos, limpieza, vactor, etc.)',
    },
    {
      'key': 'detalle',
      'q': 'Describe brevemente el problema o necesidad.',
    },
    {
      'key': 'ubicacion',
      'q': 'Â¿DÃ³nde se requiere el servicio? (direcciÃ³n o zona)',
    },
    {
      'key': 'urgencia',
      'q': 'Â¿QuÃ© tan urgente es el servicio? (ej: inmediato, esta semana, programado)',
    },
    {
      'key': 'extra',
      'q': 'Â¿AlgÃºn requerimiento especial o comentario adicional?',
    },
  ];

  void _nextStep() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;
    _answers[_questions[_step]['key']!] = answer;
    _controller.clear();
    if (_step < _questions.length - 1) {
      setState(() => _step++);
    } else {
      setState(() => _completed = true);
      widget.onComplete(_buildDescription());
    }
  }

  String _buildDescription() {
    return _questions.map((q) {
      final key = q['key']!;
      final label = q['q']!;
      final value = _answers[key] ?? '';
      return '$label\n$value';
    }).join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          const Text('Â¡Listo! DescripciÃ³n generada.'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _questions[_step]['q']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Escribe tu respuesta...',
          ),
          onSubmitted: (_) => _nextStep(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Siguiente'),
            ),
            if (_step > 0)
              TextButton(
                onPressed: () {
                  setState(() {
                    _step--;
                    _controller.text = _answers[_questions[_step]['key']!] ?? '';
                  });
                },
                child: const Text('Anterior'),
              ),
          ],
        ),
      ],
    );
  }
}

