import 'package:flutter/material.dart';
import '../../ui/widgets/corporate_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ...existing code...
import '../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  // ...existing code...
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  // ...existing code...
  // ...existing code...

  String _sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'<[^>]*>|["\r\t]'), '');
  }

  String? _marketplaceIntent(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return args['marketplaceIntent']?.toString();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshRegisteredUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      await user.reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _sanitize(_emailController.text);
      final password = _sanitize(_passwordController.text);
      print('Intentando registrar usuario: $email');
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );
      print('Usuario registrado: ${cred.user?.uid}');
      await cred.user?.updateDisplayName(_sanitize(_nameController.text));
      await cred.user?.sendEmailVerification();
      await _refreshRegisteredUser();
      print('Correo de verificación enviado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha enviado un correo de verificación. Por favor revisa tu bandeja de entrada o spam.',
            ),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      // Navegar a la pantalla de selección de rol después de registro
      print('Navegando a /role-selection');
      final intent = _marketplaceIntent(context);
      Navigator.pushReplacementNamed(
        context,
        '/role-selection',
        arguments: intent == null ? null : {'marketplaceIntent': intent},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Error desconocido';
      if (e.code == 'email-already-in-use') {
        msg = 'El correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        msg = 'Correo inválido';
      } else if (e.code == 'weak-password') {
        msg = 'Contraseña débil';
      } else {
        msg = e.message ?? 'Error de registro';
      }
      print('Error de FirebaseAuth: $msg');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on Exception catch (e) {
      if (!mounted) return;
      print('Error de timeout o general: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    final marketplaceIntent = _marketplaceIntent(context);
    final headerTitle = marketplaceIntent == 'sell'
        ? 'Activa tu cuenta vendedora'
        : marketplaceIntent == 'buy'
        ? 'Activa tu cuenta compradora'
        : 'Abre tu acceso a SaneApp';
    final headerSubtitle = marketplaceIntent == 'sell'
        ? 'Crea tu cuenta para publicar servicios ambientales, ganar visibilidad y vender dentro del marketplace.'
        : marketplaceIntent == 'buy'
        ? 'Crea tu cuenta para publicar necesidades, comparar proveedores y contratar dentro del marketplace ambiental.'
        : 'Crea tu cuenta y luego definiremos el flujo correcto para generador, proveedor o supervisor.';
    final submitLabel = marketplaceIntent == 'sell'
        ? 'Crear cuenta para vender'
        : marketplaceIntent == 'buy'
        ? 'Crear cuenta para comprar'
        : 'Registrarme';
    return SafeArea(
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: _brandGreen,
          title: const Text(
            'Crea tu cuenta SaneApp',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    headerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    headerSubtitle,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDCE7DF)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                      validator: Validators.validateFullName,
                      autofillHints: const [AutofillHints.name],
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showPassword,
                      validator: (v) =>
                          Validators.validatePassword(v, minLength: 8),
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showConfirmPassword,
                      validator: (v) => Validators.validateConfirmPassword(
                        _passwordController.text,
                        v,
                      ),
                      autofillHints: const [AutofillHints.password],
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 24),
                    CorporateButton(
                      text: submitLabel,
                      onPressed: _loading ? () {} : _register,
                      enabled: !_loading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
