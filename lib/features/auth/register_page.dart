import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController documentNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;

  String? selectedDocumentType;
  String? selectedCountry;
  String? selectedCity;

  final List<String> documentTypes = [
    'Cédula de ciudadanía',
    'Cédula de extranjería',
    'Pasaporte',
    'Documento nacional'
  ];

  final Map<String, List<String>> countriesAndCities = {
    'Colombia': ['Bogotá', 'Medellín', 'Cali', 'Barranquilla'],
    'México': ['Ciudad de México', 'Guadalajara', 'Monterrey'],
    'Argentina': ['Buenos Aires', 'Córdoba', 'Rosario'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              /// LOGO
              Image.asset(
                'assets/images/logo_saneapp.png',
                height: 80,
                width: 80,
              ),

              const SizedBox(height: 12),
              const Text(
                'SaneApp',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 32),

              /// TITULOS
              const Text(
                'Crear cuenta',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Comienza a gestionar tu salud hoy',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              /// FORMULARIO
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _inputField(
                      controller: fullNameController,
                      hint: 'Nombre completo',
                      icon: Icons.person,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),

                    const SizedBox(height: 16),

                    _inputField(
                      controller: emailController,
                      hint: 'Correo electrónico',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@') ? 'Correo inválido' : null,
                    ),

                    const SizedBox(height: 16),

                    _dropdownField(
                      hint: 'Tipo de documento',
                      icon: Icons.badge,
                      value: selectedDocumentType,
                      items: documentTypes,
                      onChanged: (value) {
                        setState(() => selectedDocumentType = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    _inputField(
                      controller: documentNumberController,
                      hint: 'Número de documento',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),

                    const SizedBox(height: 16),

                    _dropdownField(
                      hint: 'País',
                      icon: Icons.public,
                      value: selectedCountry,
                      items: countriesAndCities.keys.toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountry = value;
                          selectedCity = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _dropdownField(
                      hint: 'Ciudad',
                      icon: Icons.location_city,
                      value: selectedCity,
                      items: selectedCountry == null
                          ? []
                          : countriesAndCities[selectedCountry]!,
                      onChanged: (value) {
                        setState(() => selectedCity = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    _passwordField(
                      controller: passwordController,
                      hint: 'Contraseña',
                    ),

                    const SizedBox(height: 16),

                    _passwordField(
                      controller: confirmPasswordController,
                      hint: 'Confirmar contraseña',
                      confirm: true,
                    ),

                    const SizedBox(height: 28),

                    /// BOTÓN REGISTRAR
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Aquí va la lógica de registro (por ejemplo, con Firebase)
                            // Si el registro es exitoso:
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    /// ENLACE A LOGIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: Color(0xFF43A047),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// INPUT
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(hint, icon),
    );
  }

  /// PASSWORD
  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        if (value.length < 8) return 'Mínimo 8 caracteres';
        if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Debe tener una mayúscula';
        if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe tener un número';
        if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) return 'Debe tener un carácter especial';
        if (confirm && value != passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
      decoration: _inputDecoration(hint, Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
    );
  }

  /// DROPDOWN
  Widget _dropdownField({
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Por favor selecciona una opción' : null,
      decoration: _inputDecoration(hint, icon),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF43A047)),
      ),
    );
  }
}