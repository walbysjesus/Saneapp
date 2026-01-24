
/// Validadores de formularios para SaneApp
/// ──────────────────────────────
/// ✔ Limpio, modular y listo para producción
/// ✔ Compatible con pantallas: Register, Login, etc.


class Validators {
  Validators._();

  // ─────────────────────────────
  // EMAIL
  // ─────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  // ─────────────────────────────
  // PASSWORD
  // ─────────────────────────────
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    return null;
  }

  // ─────────────────────────────
  // CONFIRM PASSWORD
  // ─────────────────────────────
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // ─────────────────────────────
  // FULL NAME
  // ─────────────────────────────
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre completo es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'El nombre completo es demasiado corto';
    }
    return null;
  }

  // ─────────────────────────────
  // NUMERIC (opcional)
  // ─────────────────────────────
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return 'Ingresa un número válido';
    }
    return null;
  }

  // ─────────────────────────────
  // DOCUMENT TYPE / CUSTOM
  // ─────────────────────────────
  static String? validateDocument(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona un tipo de documento';
    }
    return null;
  }

  static String? validateCountry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona un país';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona una ciudad';
    }
    return null;
  }
}