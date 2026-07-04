import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PolÃ­tica de Privacidad')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'PolÃ­tica de Privacidad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 16),
            Text(
              'Esta aplicaciÃ³n recopila y utiliza informaciÃ³n personal Ãºnicamente para los fines de prestaciÃ³n de servicios ambientales, gestiÃ³n de usuarios y cumplimiento legal. No compartimos tu informaciÃ³n con terceros salvo requerimiento legal o para el funcionamiento esencial de la plataforma.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Tus datos estÃ¡n protegidos bajo las mejores prÃ¡cticas de seguridad y puedes solicitar su eliminaciÃ³n o modificaciÃ³n en cualquier momento escribiendo a soporte@saneapp.com.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Para mÃ¡s detalles, consulta los tÃ©rminos y condiciones en la siguiente pantalla.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TÃ©rminos y Condiciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'TÃ©rminos y Condiciones',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 16),
            Text(
              'El uso de SaneApp implica la aceptaciÃ³n de estos tÃ©rminos. El usuario se compromete a proporcionar informaciÃ³n veraz y a utilizar la plataforma de acuerdo a la ley. SaneApp se reserva el derecho de suspender cuentas que incumplan las normas o realicen actividades fraudulentas.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'La plataforma puede actualizar estos tÃ©rminos en cualquier momento. Se notificarÃ¡ a los usuarios sobre cambios relevantes.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

