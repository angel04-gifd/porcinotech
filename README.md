# PorcinoTech

## Cómo funcionan las cuentas y las granjas

- **Registro:** solo correo, nombre y contraseña. Todo lo que captures queda en
  la nube (Supabase) ligado a tu cuenta, no en el teléfono. Si desinstalas la
  app y la vuelves a instalar, basta con **iniciar sesión** con el mismo correo
  y contraseña para recuperar todo.
- **Después de registrarte eliges:**
  - **Crear una granja** → eres su *administrador*. Puedes crear todas las que
    quieras (3 granjas = 3 conjuntos de datos separados) y cambiar entre ellas
    con el botón de la granja en la barra superior.
  - **Unirte con un código** → eres *operador* de esa granja. El administrador
    ve el código en **Perfil > Mi granja** y se lo pasa al operador.
- **Datos separados:** cada granja solo ve sus propios cerdos, corrales,
  alimentos, consumos y partos (reglas RLS en la base).
- **Datos personales:** en **Perfil** cada persona captura nombre, teléfono y
  puesto. El administrador ve el **Equipo de la granja** (quién es cada
  operador y cómo contactarlo) y puede quitar operadores.
- La app ya trae su conexión (solo la clave pública, protegida por RLS), así
  que quien descargue el APK solo inicia sesión: no hay pantalla de servidor ni
  claves que ver o escribir.
- **Contraseña:** en el login se puede mostrar/ocultar; al registrarse pide mínimo
  8 caracteres con letras y números.
- **Recuperar contraseña:** «¿Olvidaste tu contraseña?» envía un código de 6
  dígitos al correo; con el código se escribe la nueva contraseña dentro de la
  app (sin enlaces ni navegador). Requiere el paso de correo de abajo.

### Configurar el correo de recuperación (una vez, en Supabase)
1. **Authentication > Emails > Templates > Reset Password**: reemplaza el
   contenido por algo como
   `<h2>Recupera tu contraseña</h2><p>Tu código es: <b>{{ .Token }}</b></p>`.
2. **Authentication > Sign In / Providers > Email**: sube «Minimum password
   length» a 8 y activa «Leaked password protection» si tu plan lo permite.
3. El correo de pruebas de Supabase está limitado (pocos mensajes por hora). Para
   uso real configura un SMTP propio en **Authentication > SMTP Settings**.

## Publicar el APK en GitHub Releases

La app usa el identificador `mx.utvm.porcinotech` (se cambia en
`android/app/build.gradle.kts`, línea `applicationId`; cámbialo antes de la
primera publicación, porque después Android lo trata como otra app).

1. **Llave de firma (una sola vez; guárdala, sin ella no podrás actualizar):**
   ```powershell
   keytool -genkey -v -keystore porcinotech.jks -keyalg RSA -keysize 2048 -validity 10000 -alias porcinotech
   ```
2. **Automático con GitHub:** en el repositorio, *Settings > Secrets and
   variables > Actions*, crea `ANDROID_KEYSTORE_BASE64` (el `.jks` en base64:
   `[Convert]::ToBase64String([IO.File]::ReadAllBytes("porcinotech.jks"))`),
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` y `ANDROID_KEY_PASSWORD`.
   Luego sube una etiqueta: `git tag v1.0.0` y `git push origin v1.0.0`. El
   flujo `.github/workflows/release.yml` (copia ahí el archivo `docs/release.yml`) construye el APK y lo adjunta al
   Release como `PorcinoTech.apk`.
3. **A mano:** crea `android/key.properties` con `storeFile`, `storePassword`,
   `keyAlias` y `keyPassword` y ejecuta `flutter build apk --release`; el APK
   queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Montar tu propio servidor (opcional)

1. Crea un proyecto gratuito en [supabase.com](https://supabase.com).
2. En **SQL Editor** pega y ejecuta todo `supabase/setup_completo.sql`
   (en un proyecto nuevo y vacío; crea tablas, reglas y permisos).
3. En **Authentication > Providers > Email** deja habilitado Email. Para
   pruebas puedes desactivar **Confirm email**; en producción configura SMTP.
4. En **Project Settings > API** copia la **Project URL** y la clave
   **publishable** (anon). Nunca uses `service_role` / `sb_secret_`: la app la
   rechaza.
5. Pon esos datos en `lib/core/config/app_config.dart` o compílala con
   `--dart-define-from-file=env.json` (ver `env.example.json`).

Si pierdes una contraseña, usa **¿Olvidaste tu contraseña?** en el login
(configura la URL de redirección en **Authentication > URL Configuration**).

### Ejecutar desde el código (desarrolladores)

```powershell
flutter pub get
flutter run -d chrome
```

Opcionalmente puedes dar un valor inicial de conexión con `env.json`
(copia `env.example.json`; no se sube al repositorio):

```powershell
flutter run -d chrome --dart-define-from-file=env.json
flutter build apk --release
```

Lo que se guarde en la pantalla de conexión tiene prioridad sobre `env.json`.

Si ya tenías un proyecto creado con las migraciones anteriores, no vuelvas a
ejecutar `setup_completo.sql`. Para separar las granjas ejecuta, en este orden,
`supabase/respaldo_antes_de_20261003.sql` (copia de seguridad de tus datos en el
esquema `respaldo_20261020`) y `supabase/migrations/20261003_multi_granja.sql`.
Los datos que ya existían quedan juntos en la «Granja principal» y sus cuentas
conservan su rol.

## APIs e integraciones

| API | Para qué sirve | Estado |
|---|---|---|
| Supabase Auth | Registro, inicio de sesión y sesión persistente | Activa |
| Supabase REST (PostgREST) | Lectura y escritura de cerdos, corrales, alimentos y partos con reglas RLS | Activa |
| Supabase Realtime | Cambios en vivo entre usuarios de la misma granja | Activa |
| Open-Meteo (clima y geocodificación, sin clave) | Temperatura y alerta de estrés por calor en el inicio | Activa |
| Inicio de sesión con Google | Entrar con la cuenta de Google | Pendiente (al final) |

## Alimentación

Cada corral tiene una etapa productiva (Pre-inicio, Inicio, Desarrollo,
Engorda, Gestación, Lactancia) con una ración sugerida en
`etapas_productivas`. La ración diaria se calcula sola:
`cerdos activos del corral × ración de su etapa`. Un alimento puede asignarse a
una etapa (solo cuenta los corrales de esa etapa) o a todas. Al registrar un
consumo, el trigger resta la cantidad del stock y rechaza consumos mayores que
la existencia.

## Reglas de negocio

La base de datos las hace cumplir (la app solo avisa antes):

- Una cerda tiene una sola gestación en curso. Si no llega a parir (aborto o
  monta sin preñez), se marca como **fallida** desde *Próximos partos* y queda
  libre para una nueva inseminación.
- Solo una hembra activa puede inseminarse, y no antes de su nacimiento.
- El parto real no puede registrarse antes de 100 días de la monta ni en el
  futuro.
- Una cerda con gestación en curso no puede cambiar de sexo ni pasar a vendida,
  fallecida o baja.
- Un corral no admite más cerdos activos que su capacidad (se revisa al
  ingresar o cambiar de corral).
- El peso va de 0 a 500 kg.

## Permisos por rol

Todos los integrantes de una misma granja ven los mismos datos; otra granja no. El rol (administrador/operador) es por granja.

| Acción | Administrador | Operador |
|---|---|---|
| Cerdos: ver, registrar, editar | ✅ | ✅ |
| Cerdos: eliminar (o archivar si tiene partos) | ✅ | ❌ |
| Corrales: ver y cambiar estado | ✅ | ✅ |
| Corrales: crear, editar datos, eliminar | ✅ | ❌ |
| Alimentos: ver y registrar consumo | ✅ | ✅ |
| Alimentos: crear, editar stock, eliminar | ✅ | ❌ |
| Inseminaciones y partos reales: registrar | ✅ | ✅ |
| Partos: eliminar | ✅ | ❌ |
| Etapas productivas: modificar | ❌ (catálogo común, solo lectura) | ❌ |
| Ver el código de granja e invitar operadores | ✅ | ❌ |
| Cambiar roles | Solo desde SQL Editor | ❌ |

## Instalar la app en un celular Android

La app se instala con el archivo `app-release.apk` (solo Android; en iPhone no
se puede instalar un APK). El APK no está en este repositorio: pídeselo al
administrador del proyecto por Drive o mensajería.

1. Descarga el APK en el celular (o pásalo por cable o Drive).
2. Ábrelo. Android pedirá permitir **instalar apps desconocidas** para la app
   desde la que lo abriste (Chrome, Archivos, WhatsApp…): actívalo.
3. Si aparece el aviso de **Play Protect**, elige **Instalar de todos modos**: la
   app no está en Play Store y por eso no está verificada.
4. Abre **PorcinoTech**, toca **Crear una cuenta** con tu correo y contraseña y
   elige crear tu granja (administrador) o unirte con un código (operador).
5. Necesitas internet: los usuarios de una misma granja comparten los mismos datos
   en tiempo real.

## Generar un APK nuevo (administrador)

No necesita claves de compilación (la conexión se configura dentro de la app)
y basta con haber ejecutado `supabase/setup_completo.sql`:

```powershell
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.
