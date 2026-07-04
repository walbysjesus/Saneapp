# Sistema de Roles en SaneApp

## Roles soportados
- **Generador**: Usuario que solicita servicios ambientales.
- **Proveedor**: Usuario que ofrece servicios ambientales.
- **Supervisor**: Usuario que supervisa y verifica servicios.

## Estructura en Firestore
- El campo de rol se llama `role` y puede tener los valores: `generador`, `proveedor`, `supervisor`.
- Se asigna al usuario en el registro y puede actualizarse en la selección de rol.

## Navegación y acceso
- La navegación principal redirige al usuario según su rol después del login.
- Cada pantalla principal está protegida por un guard (RoleGuard) que verifica el rol antes de mostrar el contenido.
- Si el usuario intenta acceder a una pantalla de otro rol, verá un mensaje de acceso denegado.

## Seguridad
- No es posible acceder a pantallas de otros roles mediante rutas directas.
- El control de acceso está implementado tanto en la navegación inicial como en cada pantalla principal.

## Recomendaciones
- Mantener el campo `role` y sus valores estandarizados en Firestore.
- Usar siempre el widget `RoleGuard` para proteger pantallas sensibles.
- Documentar cualquier cambio en la lógica de roles en este archivo.

## Ejemplo de uso de RoleGuard
```dart
RoleGuard(
  requiredRole: 'proveedor',
  child: ProviderMainScreen(),
)
```

## Archivos clave
- `lib/core/widgets/role_guard.dart`: Guard de roles.
- `lib/main.dart`: Navegación principal y redirección por rol.
- `features/generador/`, `features/proveedor/`, `features/supervisor/`: Pantallas específicas por rol.

---
Para dudas o mejoras, documenta aquí y consulta al equipo técnico.
