# SaneApp - Documentación técnica y de uso

## Estructura del proyecto
- lib/
  - main.dart: Punto de entrada y rutas.
  - features/: Funcionalidad principal (auth, home, admin, provider, generador, etc).
  - core/: Servicios, utilidades y modelos globales.
  - l10n/: Archivos de internacionalización (ARB).
  - ui/: Pantallas y componentes reutilizables.
- test/: Pruebas unitarias y de widgets.

## Flujos principales
- Registro y login con validación avanzada, aceptación de términos y captcha.
- Onboarding y selección de rol (cliente, proveedor, admin).
- Paneles diferenciados por rol (admin, supervisor, proveedor, generador).
- Gestión de solicitudes, subastas, documentos y pagos.
- Panel de administración con aprobación de perfiles y gestión de roles.

## Bloque 2 y 3 aplicados (KYC + seguridad)

### KYC documental proveedor
- Servicio de carga documental implementado en `lib/features/proveedor/provider_documents_service.dart`.
- Validaciones activas por archivo:
  - formatos permitidos: PDF/JPG/JPEG/PNG,
  - tamaño máximo: 10 MB,
  - tipo documental controlado (`rut`, `camara_comercio`, `cedula_representante`, `certificado_bancario`, `licencia_ambiental`).
- Cada documento se guarda en Storage bajo `provider_docs/{uid}/...` con metadatos.
- Se registra evidencia documental en Firestore:
  - `providers/{uid}` con `documentsStatus: pending_review`,
  - `users/{uid}/documents/{fieldKey}` con trazabilidad de carga.

### Seguridad Firestore
- Endurecimiento de `firestore.rules`:
  - proveedores no pueden autoactivar estado `active` en `users/{uid}`;
  - `users/{uid}/documents/{docId}` exige coherencia de `fieldKey` y URL válida;
  - `payments/{paymentId}` protege campos críticos inmutables (monto, moneda, ids, método, recibo/factura) para updates de clientes;
  - `payment_webhook_events` se define como solo lectura para admin/supervisor y sin escrituras cliente.

### Seguridad Storage
- Endurecimiento de `storage.rules`:
  - validación de tamaño y `contentType` para documentos e imágenes;
  - acceso de lectura a documentos de proveedor restringido a dueño o admin en rutas sensibles.

### Checklist de despliegue recomendado
1. Ejecutar pruebas de reglas en emulador Firebase antes de deploy.
2. Verificar que el flujo de alta proveedor termina en `pending_review` y no en `active`.
3. Confirmar que un usuario proveedor no puede modificar campos críticos de pagos.
4. Confirmar que documentos en Storage no son legibles por terceros autenticados.

## Bloque 4 aplicado (SLA + automatizaciones comerciales)

- Automatización de SLA comercial en Cloud Functions (`functions/index.js`):
  - `initializeCommercialSlaOnRequestCreate`: inicializa deadline de respuesta del proveedor al crear solicitud.
  - `handleOfferCommercialAutomation`: actualiza etapa comercial, marca respuesta dentro/fuera de SLA y registra hitos al recibir oferta.
  - `enforceCommercialSlaBreaches` (scheduler cada 30 min): detecta solicitudes vencidas, cambia estado a `provider_response_overdue` y notifica al generador.
- Se agregaron eventos de trazabilidad en `statusHistory` para auditoría operativa.
- Se agregaron notificaciones idempotentes en colección `notifications` para hitos de SLA y ofertas.

### Variables/operación recomendada para bloque 4
1. Verificar que Cloud Scheduler esté habilitado en el proyecto Firebase.
2. Revisar permisos de la cuenta de servicio de Functions para ejecutar scheduler y escribir en Firestore.
3. Monitorear en logs eventos `sla_initialized`, `offer_received` y `sla_breached`.

## Bloque 5 aplicado (indices y escalabilidad Firestore)

- Se definieron indices compuestos en `firestore.indexes.json` para consultas criticas de app y backend:
  - `users`: `role + status`
  - `provider_services`: `providerId + isActive`
  - `solicitudes`: `status + type`
  - `solicitudes`: `selectedProveedorId + status`
  - `solicitudes`: `supervisorId + supervisorStatus`
  - `solicitudes`: `slaStatus + providerResponseDeadlineAt`
  - `ofertas`: `solicitudId + price`
  - `billing_records`: `providerId + documentType`

### Despliegue de indices
```bash
firebase deploy --only firestore:indexes
```

### Verificacion operativa
1. Abrir la app y revisar vistas de proveedor/supervisor con filtros activos.
2. Confirmar que no aparecen errores de indice faltante en consultas de `solicitudes` y `ofertas`.
3. Validar en logs de Functions que el scheduler de SLA consulta sin errores de index.

## Bloque 6 aplicado (QA pre-release y estabilidad de tests)

- Se reforzaron pruebas de integracion con bootstrap comun de Firebase para evitar errores `[core/no-app]`.
- Se estabilizaron los tests criticos de onboarding/home y registro proveedor para ejecucion local en Windows.
- Se añadieron scripts de chequeo release para flujo local:
  - `run_release_checks.bat`
  - `run_release_checks.ps1`
- Validacion actual:
  - `test/integration/onboarding_login_home_flow_test.dart` en verde.
  - `test/integration/app_startup_test.dart` en verde.
  - `test/integration/provider_registration_flow_test.dart` en verde.

## Bloque 7 aplicado (hardening de catalogo categorias/subcategorias)

- Limpieza de codigo legacy en `provider_profile_setup_screen.dart`:
  - Eliminados widgets duplicados no usados (`_CategoryDropdown`, `_CategorySelector`) y bloques de ejemplo hardcodeados.
- Normalizacion de categorias guardadas historicamente por nombre:
  - Ahora se resuelven a IDs tecnicos del catalogo Firestore antes de cargar subcategorias o persistir cambios.
  - Esto evita desalineacion entre datos legacy y consultas reales por ID.
- Resiliencia de UI de subcategorias:
  - Removidos prints de debug en pantalla productiva.
  - Mensajes de error/estado vacio ajustados para mejor legibilidad.
- Cobertura de prueba agregada:
  - `Normaliza categorias legacy guardadas por nombre` en `test/integration/provider_registration_flow_test.dart`.

## Bloque 8 aplicado (observabilidad de catalogo + pipeline release PowerShell)

- Se agregaron eventos de analitica para el ciclo de catalogo proveedor:
  - carga de catalogo de categorias,
  - uso de fallback de categorias,
  - normalizacion de categorias legacy,
  - carga/fallo de subcategorias,
  - seleccion de subcategoria en experiencia de navegacion.
- Se ajusto `run_release_checks.ps1` para que `flutter analyze` no detenga el pipeline por infos y warnings de deuda historica, manteniendo el bloqueo para errores reales de compilacion.
- Resultado esperado en entorno local:
  - mayor trazabilidad operativa del modulo de categorias/subcategorias,
  - menor fragilidad del pipeline de pre-release en Windows.

## Bloque 9 aplicado (migracion legacy de categorias/subcategorias)

- Se implemento y ejecuto script de migracion en `functions/migrate_categories_legacy.js` para normalizar valores legacy guardados por nombre.
- Ejecucion validada en proyecto `saneapp-clean`:
  - dry-run inicial sin cambios pendientes,
  - apply idempotente sin cambios adicionales,
  - dry-run post-apply sin pendientes.
- Estado resultante:
  - `changed: 0`,
  - `unresolved: 0`,
  - sin documentos pendientes de normalizacion en las colecciones inspeccionadas.

## Bloque 10 aplicado (auditoria continua de consistencia de catalogo)

- Se agrego script read-only `functions/audit_category_catalog_consistency.js` para auditoria operativa de `providers` y `users`.
- La auditoria clasifica documentos en:
  - limpios,
  - con valores legacy resolubles,
  - con inconsistencias no resueltas (desconocidos, ambiguos o subcategorias fuera de alcance).
- Script de ejecucion incluido en `functions/package.json`:
  - `npm run audit:categories:consistency`
- Uso recomendado pre-release:
  1. Ejecutar migracion legacy (dry/apply/dry) cuando se detecte deuda historica.
  2. Ejecutar auditoria de consistencia y revisar muestras `samples`.
  3. Corregir manualmente los documentos reportados como `unresolved`.

## Bloque 11 aplicado (gate de release + reporte exportable + scheduler semanal)

- Se reforzo `functions/audit_category_catalog_consistency.js` con capacidades operativas:
  - gate por inconsistencias no resueltas (`--fail-on-unresolved`),
  - exporte de reporte JSON (`--out=...`),
  - persistencia opcional en Firestore (`--write-firestore-report`).
- Scripts agregados en `functions/package.json`:
  - `npm run audit:categories:gate`
  - `npm run audit:categories:export`
- Se agrego chequeo de gate al pipeline local en `run_release_checks.ps1`:
  - si existe `GOOGLE_APPLICATION_CREDENTIALS` valido, ejecuta el gate y falla ante `unresolved > 0`.
  - si no existe credencial, informa omision; puede hacerse obligatorio con `RELEASE_STRICT_CATALOG_AUDIT=1`.
- Se agrego scheduler semanal en Cloud Functions:
  - `weeklyCategoryCatalogAudit` en `functions/index.js` (lunes 06:00, America/Bogota),
  - guarda reporte en Firestore dentro de `operational_audits/category_catalog/runs/{reportId}`,
  - emite logs de error si detecta pendientes `unresolved`.

## Bloque 12 aplicado (hardening final de guardado en onboarding proveedor)

- Se agrego sanitizacion defensiva justo antes de persistir en `ProviderProfileSetupScreen`:
  - normaliza categorias seleccionadas contra IDs vigentes del catalogo,
  - recorta subcategorias fuera del alcance de las categorias elegidas,
  - recarga subcategorias si hace falta para validar correctamente antes del guardado.
- El hardening aplica para ambos flujos de salida del paso:
  - `Siguiente`,
  - `Llenar despues`.
- Se agregaron eventos de analitica para poda en guardado:
  - `provider_catalog_categories_pruned_on_save`,
  - `provider_catalog_subcategories_pruned_on_save`.
- Cobertura agregada en integracion:
  - `Poda subcategorias fuera del alcance de categorias al guardar` en `test/integration/provider_registration_flow_test.dart`.

## Bloque 13 aplicado (validacion cruzada server-side de catalogo)

- Se agrego `functions/validate_category_catalog.js`:
  - Funcion reutilizable `validateCategoriesCatalogConsistency` para validar categorias/subcategorias contra el catalogo vigente.
  - Clasifica errores en `error` (categorias desconocidas, subcategorias sin categoria padres) y `warning` (subcategorias fuera de alcance).
  - No rechaza escrituras; registra logs para auditoría y debugging.
- Se agregaron triggers en `functions/index.js`:
  - `validateProviderCatalogOnWrite` en colección `providers`.
  - `validateUserCatalogOnWrite` en colección `users`.
  - Ambos se disparan al cambiar `selectedCategories` o `selectedSubcategories`.
  - Emiten logs críticos (`warn`) si hay inconsistencias de error nivel y logs informativos (`info`) si hay warnings.
- Proposito:
  - Detectar escrituras inválidas desde clientes legacy, integraciones externas o intentos de manipulación.
  - Proporcionar trazabilidad en logs para investigación operativa post-escritura.
  - Complementar validación cliente con barrera server-side.


## Buenas prácticas
- Seguridad: Validación de datos, captcha, roles y permisos.
- Internacionalización: Uso de AppLocalizations y archivos ARB.
- Accesibilidad: Uso de Semantics y textos descriptivos.
- Optimización: Uso de const widgets, paginación y lazy loading.
- Cumplimiento legal: Pantallas de términos y privacidad, consentimiento explícito.

## Scripts útiles
- flutter pub get: Instala dependencias.
- flutter test: Ejecuta pruebas.
- flutter run: Ejecuta la app.
- `flutterw.bat <comando>`: ejecuta Flutter usando `android/local.properties` sin depender del PATH global.
- `powershell -ExecutionPolicy Bypass -File .\flutterw.ps1 <comando>`: alternativa estable para PowerShell.

## Ejecucion en equipos con 4 GB de RAM
- Consulta la guia dedicada en [RUN_4GB.md](RUN_4GB.md).
- Preferir dispositivo fisico antes que emulador.
- Ejecutar desde terminal con `flutter run -d <deviceId> --debug`.
- Si necesitas compilar con menor carga visual, usa `build_android.bat`.

## Contacto y soporte
- Para dudas técnicas, revisa la carpeta /docs o contacta al equipo de desarrollo.

---

## ESTADO ACTUAL DE DEPLOYMENT (2026-07-03)

### Resumen Ejecutivo
- ✅ **Bloques implementados**: 13/13 (100% código)
- ✅ **Pruebas locales**: 5 integration tests, todos pasando
- ✅ **Auditoría de datos**: 0 documentos legacy, 0 inconsistencias
- 🔴 **Despliegue**: Bloqueado por timeout de Firebase CLI en Windows

### Bloqueo Técnico Identificado
**Problema**: Firebase CLI (`firebase-tools@15.22.3`) no puede completar el análisis del archivo `functions/index.js` (1100+ líneas, 50+ funciones) dentro del límite de 10 segundos en entorno Windows/PowerShell.

**Error**: 
```
Error: User code failed to load. Cannot determine backend specification. Timeout after 10000.
```

**Root Cause**: Limitación de rendimiento en análisis de código de firebase-tools en Windows. El archivo es muy grande y el CLI no puede procesarlo en tiempo suficiente.

### Soluciones Disponibles

#### Opción 1: Actualizar firebase-tools (Recomendado - Prueba primero)
```powershell
npm install -g firebase-tools@latest
# Versión actual: 15.22.3, disponible 15.22.4
```

#### Opción 2: Refactorizar funciones en módulos más pequeños
1. Extraer funciones helper a `functions/handlers/` subdirectorio
2. Crear `functions/index.js` que solo importe y re-export las funciones
3. Intentar deploy nuevamente (archivos más pequeños se analizan más rápido)

Ejemplo estructura:
```
functions/
  index.js (solo 50 líneas: imports + exports)
  handlers/
    sla.js (funciones de SLA)
    payments.js (funciones de pagos)
    supervisor.js (funciones de supervisores)
    categories.js (funciones de categorías)
    helpers.js (funciones auxiliares)
```

#### Opción 3: Deploy manual via Firebase Console
1. Ir a https://console.firebase.google.com/u/0/project/saneapp-clean/functions
2. Usar "Create Function" manualmente para cada función crítica
3. Copiar código de `index.js` a cada función

#### Opción 4: Usar gcloud CLI (si está disponible)
```bash
gcloud functions deploy initializeCommercialSlaOnRequestCreate \
  --runtime nodejs22 \
  --region us-central1 \
  --source=./functions
```

### Pasos Recomendados Inmediatos
1. **Hoy**: Actualizar `firebase-tools` a la última versión y reintentar deploy
2. **Si aún falla**: Refactorizar `functions/index.js` siguiendo Opción 2
3. **Validación post-deploy**: 
   - Ejecutar `npm run audit:categories:gate` en functions/
   - Verificar Cloud Scheduler activado en Firebase Console
   - Confirmar validación triggers ejecutándose en logs

### Archivos Críticos para Deploy
- `functions/index.js`: Punto de entrada (actualmente 1100+ líneas)
- `functions/package.json`: Dependencias (firebase-admin@12.7.0, firebase-functions@5.1.1)
- `functions/audit_category_catalog_consistency.js`: Módulo de auditoría (Block 11)
- `functions/validate_category_catalog.js`: Módulo de validación (Block 13)
- `functions/migrate_categories_legacy.js`: Script de migración (Block 9)

### Verificación de Éxito Post-Deploy
Una vez que el deploy completa exitosamente, validar:
```powershell
# En directorio project root
firebase functions:list --project saneapp-clean

# Debería mostrar ~50+ funciones deployadas
# Ejemplos: initializeCommercialSlaOnRequestCreate, handlePaymentWebhook, etc.

# En directorio functions/
npm run audit:categories:gate

# Debería retornar: "unresolved: 0" sin error de exit code
```

### Próximas Acciones (Post-Deploy)
- Bloque 14: Monitoring y alertas en Cloud Logging
- Bloque 15: Rate limiting y protección contra abuso
- Bloque 16: Backup automático y disaster recovery

