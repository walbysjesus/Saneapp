import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../core/utils/validators.dart';
import 'package:saneapp_pro_nuevo/models/user_model.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);
const _cardBorder = Color(0xFFDCE7DF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _marketplaceIntent(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return args['marketplaceIntent']?.toString();
    }
    return null;
  }

  Object? _marketplaceArguments(BuildContext context) {
    final intent = _marketplaceIntent(context);
    return intent == null ? null : {'marketplaceIntent': intent};
  }

  void _routeAfterLogin({
    required UserRole? role,
    required UserModel userModel,
    required Map<String, dynamic> userData,
  }) {
    final intent = _marketplaceIntent(context);
    final status = userData['status']?.toString() ?? userModel.status ?? '';

    if (role == UserRole.supervisor) {
      final profileCompleted = userModel.supervisorProfileCompleted;
      if ((status == 'active' || status == 'prequalified') &&
          profileCompleted) {
        Navigator.pushReplacementNamed(context, '/supervisor-dashboard');
      } else if (profileCompleted) {
        Navigator.pushReplacementNamed(
          context,
          '/supervisor-application-status',
        );
      } else {
        Navigator.pushReplacementNamed(context, '/supervisor-profile-setup');
      }
      return;
    }

    if (role == UserRole.generador) {
      if (!userModel.clientProfileCompleted) {
        Navigator.pushReplacementNamed(context, '/client-profile');
        return;
      }
      if (intent == 'buy') {
        Navigator.pushReplacementNamed(
          context,
          '/crear_solicitud',
          arguments: {
            'requestSource': 'service_marketplace',
            'requestTitle': 'Solicitud desde marketplace ambiental',
          },
        );
        return;
      }
      Navigator.pushReplacementNamed(context, '/buyer_main');
      return;
    }

    if (role == UserRole.proveedor) {
      final profileCompleted = userData['profileCompleted'] == true;
      if (!profileCompleted) {
        Navigator.pushReplacementNamed(context, '/provider-profile-setup');
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        intent == 'sell' ? '/provider_main' : '/marketplace',
      );
      return;
    }

    if (role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      intent == null ? '/marketplace' : '/role-selection',
      arguments: _marketplaceArguments(context),
    );
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _loading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.token);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        facebookAuthCredential,
      );
      final user = userCredential.user;
      if (user == null) throw Exception('No se pudo autenticar con Facebook');
      // Verificar si el usuario ya existe en Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) {
        // Guardar datos mínimos
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'fullName': user.displayName,
          'photoUrl': user.photoURL,
          'role': 'generador',
          'clientProfileCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // Obtener datos actualizados
      final userData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data() ??
          {};
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        fullName: userData['fullName'] as String?,
        photoUrl: userData['photoUrl'] as String?,
        companyName: userData['companyName'] as String?,
        role: userData['role'] as String?,
        entityType: userData['entityType'] as String?,
        clientType: userData['clientType'] as String?,
        clientProfileCompleted:
            userData['clientProfileCompleted'] as bool? ?? false,
        verificationStatus: null,
        verifiedAt: null,
        completedServiceIds: [],
      );
      if (!mounted) return;
      Provider.of<AppState>(
        context,
        listen: false,
      ).setUser(userModel, UserRole.generador);
      _routeAfterLogin(
        role: UserRole.generador,
        userModel: userModel,
        userData: userData,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error con Facebook: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) throw Exception('No se pudo autenticar con Google');
      // Verificar si el usuario ya existe en Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'fullName': user.displayName,
          'photoUrl': user.photoURL,
          'role': 'generador',
          'clientProfileCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // Obtener datos actualizados
      final userData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data() ??
          {};
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        fullName: userData['fullName'] as String?,
        photoUrl: userData['photoUrl'] as String?,
        companyName: userData['companyName'] as String?,
        role: userData['role'] as String?,
        entityType: userData['entityType'] as String?,
        clientType: userData['clientType'] as String?,
        clientProfileCompleted:
            userData['clientProfileCompleted'] as bool? ?? false,
        verificationStatus: null,
        verifiedAt: null,
        completedServiceIds: [],
      );
      if (!mounted) return;
      Provider.of<AppState>(
        context,
        listen: false,
      ).setUser(userModel, UserRole.generador);
      _routeAfterLogin(
        role: UserRole.generador,
        userModel: userModel,
        userData: userData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error con Google: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  String sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'<[^>]*>|["\r\n\t]'), '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Form(
              key: _formKey,
              child: Column(
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
                        Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/images/logo_saneapp.png',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Accede a tu cuenta para continuar con tu flujo de generador, proveedor, supervisor o administración.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
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
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
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
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) =>
                              Validators.validatePassword(value, minLength: 8),
                          autofillHints: const [AutofillHints.password],
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading ? null : _resetPassword,
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: _brandGreenSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.facebook,
                        color: Color(0xFF1877F3),
                        size: 24,
                      ),
                      label: const Text('Iniciar sesión con Facebook'),
                      onPressed: _loading ? null : _loginWithFacebook,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: _brandGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.g_mobiledata,
                        color: Color(0xFF4285F4),
                        size: 28,
                      ),
                      label: const Text('Iniciar sesión con Google'),
                      onPressed: _loading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: _brandGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      '¿No tienes cuenta? Regístrate',
                      style: TextStyle(
                        color: _brandGreenSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = sanitize(_emailController.text);
      final password = sanitize(_passwordController.text);

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw FirebaseAuthException(
                code: 'timeout',
                message:
                    'La conexiÃ³n estÃ¡ tardando demasiado. Intenta de nuevo.',
              );
            },
          );

      // Obtener el documento del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final roleStr = userData['role'] as String?;
      final status = userData['status'] as String?;
      UserRole? role;
      switch (roleStr) {
        case 'generador':
          role = UserRole.generador;
          break;
        case 'proveedor':
          role = UserRole.proveedor;
          break;
        case 'admin':
          role = UserRole.admin;
          break;
        case 'supervisor':
          role = UserRole.supervisor;
          break;
        default:
          role = null;
      }

      // Crear el UserModel con los datos del usuario
      final userModel = UserModel(
        uid: userCredential.user?.uid ?? '',
        email: userCredential.user?.email ?? '',
        fullName: userData['fullName'] as String?,
        photoUrl: userData['photoUrl'] as String?,
        companyName: userData['companyName'] as String?,
        role: roleStr,
        entityType: userData['entityType'] as String?,
        clientType: userData['clientType'] as String?,
        status: status,
        clientProfileCompleted:
            userData['clientProfileCompleted'] as bool? ?? false,
        supervisorProfileCompleted:
            userData['supervisorProfileCompleted'] as bool? ?? false,
        supervisorAssessmentPassed:
            userData['supervisorAssessmentPassed'] as bool? ?? false,
        supervisorAssessmentScore:
            (userData['supervisorAssessmentScore'] as num?)?.toInt(),
        verificationStatus: null, // Puedes mapearlo si lo usas
        verifiedAt: null, // Puedes mapearlo si lo usas
        completedServiceIds: [], // Puedes mapearlo si lo usas
      );

      // Asignar usuario y rol en AppState
      if (mounted) {
        if (role == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tu cuenta no tiene rol asignado. Contacta soporte.',
              ),
            ),
          );
          return;
        }
        Provider.of<AppState>(context, listen: false).setUser(userModel, role);
        if (status == 'pending') {
          Navigator.pushReplacementNamed(context, '/verification');
          return;
        }
        _routeAfterLogin(role: role, userModel: userModel, userData: userData);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          msg = 'ContraseÃ±a incorrecta';
          break;
        case 'invalid-email':
          msg = 'Correo invÃ¡lido';
          break;
        default:
          msg = e.message ?? 'Error de autenticaciÃ³n';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un correo vÃ¡lido para recuperar la contraseÃ±a',
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de recuperación enviado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
