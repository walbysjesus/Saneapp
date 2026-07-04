import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/services/rating_service.dart';

class RateServiceScreen extends StatefulWidget {
  final String serviceId;
  final String fromUserId;
  final String toUserId;
  final String role; // 'client_to_provider' o 'provider_to_client'

  const RateServiceScreen({
    super.key,
    required this.serviceId,
    required this.fromUserId,
    required this.toUserId,
    required this.role,
  });

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  int _stars = 5;
  final _commentController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await RatingService.rateService(
        serviceId: widget.serviceId,
        fromUserId: widget.fromUserId,
        toUserId: widget.toUserId,
        role: widget.role,
        stars: _stars,
        comment: _commentController.text.trim(),
      );
      setState(() => _submitted = true);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Â¡Gracias por tu calificaciÃ³n!'),
          content: const Text('Tu opiniÃ³n ayuda a mejorar la comunidad.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Regresa al detalle
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Calificar servicio')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('Â¿CÃ³mo calificarÃ­as este servicio?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    _stars > i ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: _submitted ? null : () => setState(() => _stars = i + 1),
                )),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                enabled: !_submitted,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: _loading || _submitted ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar calificaciÃ³n'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


