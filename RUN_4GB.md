# SaneApp - Ejecucion en equipos con 4 GB de RAM

Este proyecto ya tiene una configuracion de Gradle reducida para minimizar el consumo de memoria durante el arranque y la compilacion en Android.

## Recomendacion principal

Usa siempre un dispositivo fisico con `flutter run`.

```bash
flutter run -d <deviceId> --debug
```

Si tu terminal presenta inconsistencias con `flutter` en PATH, usa el wrapper local del proyecto:

```bash
flutterw.bat run -d <deviceId> --debug
```

En PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\flutterw.ps1 run -d <deviceId> --debug
```

## Antes de ejecutar

1. Cierra emuladores de Android.
2. Cierra otras apps pesadas como navegadores con muchas pestañas.
3. Deja solo una ventana de VS Code abierta si es posible.
4. Ejecuta desde la raiz del proyecto:

```bash
flutterw.bat pub get
flutterw.bat run -d <deviceId> --debug
```

## Si el primer arranque es pesado

- Espera a que termine la resolucion de dependencias la primera vez.
- Si Android Studio se queda sin memoria, usa `flutter run` desde terminal en lugar del IDE.
- Si necesitas compilar sin depender del IDE, usa el script `build_android.bat` para generar el APK debug con menos carga sobre la interfaz.

## Ajustes ya aplicados para baja RAM

- `org.gradle.jvmargs` reducido en `android/gradle.properties`.
- Un solo worker de Gradle.
- Cache y paralelismo desactivados.
- Daemon de Gradle deshabilitado.

## Si falla la ejecucion

- Verifica que `android/local.properties` apunte a tu instalacion de Flutter y Android SDK.
- Verifica que el dispositivo este autorizado con `flutter devices`.
- Si hay error de memoria, reinicia la terminal y vuelve a ejecutar el comando.
