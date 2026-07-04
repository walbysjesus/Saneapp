import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validateEmail retorna error si el email es vacÃ­o', () {
      expect(Validators.validateEmail(''), 'El email es obligatorio');
    });
    test('validateEmail retorna error si el email es invÃ¡lido', () {
      expect(Validators.validateEmail('correo@'), 'Email invÃ¡lido');
    });
    test('validateEmail retorna null si el email es vÃ¡lido', () {
      expect(Validators.validateEmail('test@mail.com'), null);
    });
    test('validatePassword retorna error si la contraseÃ±a es vacÃ­a', () {
      expect(Validators.validatePassword(''), 'La contraseÃ±a es obligatoria');
    });
    test('validatePassword retorna error si la contraseÃ±a es corta', () {
      expect(Validators.validatePassword('12345'), 'La contraseÃ±a debe tener al menos 8 caracteres');
    });
    test('validatePassword retorna null si la contraseÃ±a es vÃ¡lida', () {
      expect(Validators.validatePassword('12345678'), null);
    });
    test('validateConfirmPassword retorna error si confirmaciÃ³n es vacÃ­a', () {
      expect(Validators.validateConfirmPassword('12345678', ''), 'Confirma tu contraseÃ±a');
    });
    test('validateConfirmPassword retorna error si no coincide', () {
      expect(Validators.validateConfirmPassword('12345678', '87654321'), 'Las contraseÃ±as no coinciden');
    });
    test('validateConfirmPassword retorna null si coincide', () {
      expect(Validators.validateConfirmPassword('12345678', '12345678'), null);
    });
  });
}


