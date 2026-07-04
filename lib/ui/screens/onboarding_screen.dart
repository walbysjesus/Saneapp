
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _buttonDisabled = false;
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkIfSeen();
  }

  Future<void> _checkIfSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('onboarding_seen') == true) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/marketplace');
      }
    } catch (e) {
      // Si hay error, simplemente muestra el onboarding
    }
  }

  List<_OnboardingPage> get _pages {
    final loc = AppLocalizations.of(context);
    return [
      _OnboardingPage(
        title: loc?.onboarding_title1 ?? 'Bienvenido a SaneApp',
        description: loc?.onboarding_desc1 ?? 'La plataforma B2B para servicios confiables, cotizaciones y gestión empresarial.',
        image: 'assets/images/logo_saneapp.png',
      ),
      _OnboardingPage(
        title: loc?.onboarding_title2 ?? 'Solicita y Cotiza',
        description: loc?.onboarding_desc2 ?? 'Gestiona solicitudes, recibe cotizaciones y elige la mejor opción para tu empresa.',
        image: 'assets/images/logo_saneapp.png',
      ),
      _OnboardingPage(
        title: loc?.onboarding_title3 ?? 'Confianza y Trazabilidad',
        description: loc?.onboarding_desc3 ?? 'Verifica empresas, consulta historial y asegura la trazabilidad legal de cada servicio.',
        image: 'assets/images/logo_saneapp.png',
      ),
      _OnboardingPage(
        title: loc?.onboarding_title4 ?? '¡Comienza ahora!',
        description: loc?.onboarding_desc4 ?? 'Crea tu cuenta y lleva tu empresa al siguiente nivel con SaneApp.',
        image: 'assets/images/logo_saneapp.png',
      ),
    ];
  }

  Future<void> _nextPage() async {
    if (_buttonDisabled) return;
    setState(() => _buttonDisabled = true);
    try {
      if (_currentPage < _pages.length - 1) {
        await _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_seen', true);
        } catch (e) {
          // Ignorar error al guardar preferencia de onboarding
        }
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/marketplace');
        }
      }
    } finally {
      if (mounted) setState(() => _buttonDisabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _OnboardingContent(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => _buildDot(i)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_currentPage == _pages.length - 1 ? 'Comenzar' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      width: _currentPage == index ? 16 : 8,
      height: 8,
      // child debe ir al final segÃºn la convenciÃ³n
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final String image;
  const _OnboardingPage({required this.title, required this.description, required this.image});
}

class _OnboardingContent extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              label: page.title,
              child: Image.asset(
                page.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

