<div align="center">

<img src="assets/images/logo.png" alt="Logo de PorcinoTech" width="140" />

# PorcinoTech 🐖🌾

**Administra tu granja porcina desde el celular: cerdos, corrales, alimento y partos, todo en un solo lugar y en tiempo real.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-00B0FF?style=for-the-badge)

[📥 Descargar APK](../../releases/latest) · [🚜 Funciones](#-funciones) · [🧪 Testers](#-zona-de-testers) · [💬 Observaciones](#-observaciones-y-comentarios) · [🔧 Desarrolladores](#-para-desarrolladores)

</div>

---

PorcinoTech es una app móvil para llevar el control de una granja porcina: registra tus cerdos, organiza los corrales, calcula la ración diaria, da seguimiento a las gestaciones y consulta el clima para prevenir el estrés por calor.

Hecha con **Flutter + Supabase**. No necesitas configurar nada: instalas la app, creas tu cuenta y listo.

---

# 🐖 Para usuarios

## 📥 Instalar en tu teléfono

1. Descarga **`PorcinoTech.apk`** desde la sección [**Releases**](../../releases/latest) de este repositorio.
2. Ábrelo en tu teléfono Android. Si te lo pide, permite **"Instalar apps desconocidas"** para el navegador o administrador de archivos que usaste.
3. Si aparece el aviso de **Play Protect**, elige **Instalar de todos modos** (la app no está en Play Store, por eso no está verificada).
4. Abre **PorcinoTech**, toca **Crear una cuenta** y elige: **crear tu granja** (administrador) o **unirte con un código** (operador).

> 📶 Necesitas conexión a internet: los usuarios de una misma granja comparten los datos en tiempo real.
> 🤖 Solo Android: en iPhone no se puede instalar un APK.

## 🚜 Funciones

- 🐽 **Cerdos:** registro, edición y archivo, con arete único y control de peso.
- 🏚️ **Corrales:** capacidad, estado y etapa productiva de cada uno.
- 🌽 **Alimentación automática:** la ración diaria se calcula sola según los cerdos y la etapa de cada corral, y el stock se descuenta al registrar consumos.
- 🍼 **Inseminaciones y partos:** próximos partos, gestaciones fallidas y partos reales con reglas de negocio.
- 📈 **Panel de inicio:** gráfica de consumo y ☀️ **clima en vivo** con alerta de estrés por calor.
- 🏡 **Multigranja:** crea todas las granjas que quieras, cada una con sus datos separados, y cambia entre ellas con un toque.
- 🔑 **Cuentas seguras:** registro con correo, contraseña con mínimo 8 caracteres (letras y números) y recuperación con código de 6 dígitos, sin salir de la app.
- ☁️ **Todo en la nube:** si desinstalas la app, inicias sesión y recuperas tus datos.
- 🔄 **Tiempo real:** los cambios de un compañero se ven al instante en la misma granja.

## 🧑‍🌾 Cuentas y granjas

- **Registro:** con correo y contraseña, o con **Continuar con Google**. Todo queda en la nube ligado a tu cuenta.
- **Unirte con un código** → eres **operador**. Todas las cuentas nuevas entran así: el administrador ve el código en **Perfil > Mi granja** y se lo comparte.
- **Crear una granja** → solo la cuenta del **administrador autorizado** puede hacerlo. Puede tener varias y cambiar entre ellas con el botón de la granja en la barra superior.
- **Datos separados:** cada granja solo ve sus propios cerdos, corrales, alimentos, consumos y partos.
- **Equipo:** en **Perfil** cada persona captura nombre, teléfono y puesto; el administrador ve al **Equipo de la granja** y puede quitar operadores.

### 🔒 Permisos por rol

Todos los integrantes de una misma granja ven los mismos datos; otra granja no. El rol (administrador/operador) es **por granja**.

| Acción | Administrador | Operador |
|---|:---:|:---:|
| Cerdos: ver, registrar, editar | ✅ | ✅ |
| Cerdos: eliminar (o archivar si tiene partos) | ✅ | ❌ |
| Corrales: ver y cambiar estado | ✅ | ✅ |
| Corrales: crear, editar datos, eliminar | ✅ | ❌ |
| Alimentos: ver y registrar consumo | ✅ | ✅ |
| Alimentos: crear, editar stock, eliminar | ✅ | ❌ |
| Inseminaciones y partos reales: registrar | ✅ | ✅ |
| Partos: eliminar | ✅ | ❌ |
| Ver el código de granja e invitar operadores | ✅ | ❌ |

## 🌽 Alimentación

Cada corral tiene una etapa productiva (**Pre-inicio, Inicio, Desarrollo, Engorda, Gestación, Lactancia**) con una ración sugerida. La ración diaria se calcula sola:

`cerdos activos del corral × ración de su etapa`

Un alimento puede asignarse a una etapa (solo cuenta los corrales de esa etapa) o a todas. Al registrar un consumo, se resta del stock y no se permiten consumos mayores que la existencia.

## 📋 Reglas de la app

La base de datos las hace cumplir (la app solo avisa antes):

- Una cerda tiene una sola gestación en curso. Si no llega a parir, se marca como **fallida** desde *Próximos partos* y queda libre para una nueva inseminación.
- Solo una hembra activa puede inseminarse, y no antes de su nacimiento.
- El parto real no puede registrarse antes de 100 días de la monta ni en el futuro.
- Una cerda con gestación en curso no puede cambiar de sexo ni pasar a vendida, fallecida o baja.
- Un corral no admite más cerdos activos que su capacidad.
- El peso va de 0 a 500 kg.

---

# 🧪 Zona de testers

¿Eres tester? Gracias por ayudar a probar la app. Cada quien tiene **su propio apartado con su nombre** para dejar sus comentarios:

| Tester | Su apartado |
|---|---|
| [@A1ex9915](https://github.com/A1ex9915) | [📝 Mis observaciones](testers/A1ex9915.md) |
| [@belemmart](https://github.com/belemmart) | [📝 Mis observaciones](testers/belemmart.md) |
| [@Julio10Mon](https://github.com/Julio10Mon) | [📝 Mis observaciones](testers/Julio10Mon.md) |

Lee la [**guía para testers**](testers/README.md): cómo participar, qué conviene probar y las reglas rápidas.

> 🔓 Este repositorio es **público**: lo que escribas en tu apartado lo puede ver cualquiera. No pongas contraseñas ni datos reales.

## 💬 Observaciones y comentarios

¿Encontraste un error o tienes una idea? Además de tu apartado, puedes reportarlo desde **Issues**:

👉 [**Dejar una observación**](../../issues/new?template=observacion.yml)

1. Pulsa **Submit new issue** después de llenar el formulario (tipo, parte de la app y descripción).
2. Si es un error, agrega los pasos para repetirlo y una captura de pantalla.
3. Te avisaré por GitHub cuando lo revise o lo resuelva.

Puedes ver todas las observaciones en la pestaña [Issues](../../issues).

---

# 🔧 Para desarrolladores

<details>
<summary><b>🧩 Arquitectura y estructura del proyecto</b></summary>

| Pieza | Servicio |
|---|---|
| Registro e inicio de sesión | Supabase Auth |
| Datos (cerdos, corrales, alimentos, partos) | Supabase REST (PostgREST) con reglas RLS |
| Cambios en vivo entre usuarios | Supabase Realtime |
| Clima y geocodificación (sin clave) | Open-Meteo |
| Inicio de sesión con Google | Pendiente |

```
lib/
├── main.dart                 Arranque de la app
├── core/
│   ├── config/               Conexión (app_config.dart)
│   ├── router/               Rutas (go_router)
│   ├── supabase/             Cliente de Supabase
│   └── widgets/              Layout principal
└── features/
    ├── auth/                 Login, registro y recuperar contraseña
    ├── farms/                Crear/unirse a granja y cambiar de granja
    ├── dashboard/            Inicio: consumo y clima
    ├── cerdos/               Registro de cerdos y reglas
    ├── corrales/             Corrales
    ├── alimentos/            Alimentos, etapas y plan de alimentación
    ├── partos/               Inseminaciones y partos
    └── profile/              Datos personales y equipo de la granja
assets/images/                Logo e ícono de la app
supabase/                     Esquema SQL, migraciones y plantilla de correo
testers/                      Apartado de cada tester
.github/workflows/            Publicación automática del APK
```

La app ya trae su conexión (solo la clave pública, protegida por RLS), así que quien descargue el APK solo inicia sesión. Cambiar roles se hace solo desde el SQL Editor de Supabase.

</details>

<details>
<summary><b>💻 Compilar desde el código</b></summary>

**Requisitos:** [Flutter](https://docs.flutter.dev/get-started/install) y una cuenta gratuita en [Supabase](https://supabase.com) (solo si montas tu propio servidor).

```powershell
flutter pub get
flutter run -d chrome
```

Opcionalmente puedes dar un valor inicial de conexión con `env.json` (copia `env.example.json`; no se sube al repositorio):

```powershell
flutter run -d chrome --dart-define-from-file=env.json
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

</details>

<details>
<summary><b>🗃️ Montar tu propio servidor (opcional)</b></summary>

1. Crea un proyecto gratuito en [supabase.com](https://supabase.com).
2. En **SQL Editor** pega y ejecuta todo `supabase/setup_completo.sql` (en un proyecto nuevo y vacío: crea tablas, reglas y permisos).
3. En **Authentication > Providers > Email** deja habilitado Email. Para pruebas puedes desactivar **Confirm email**; en producción configura SMTP.
4. En **Project Settings > API** copia la **Project URL** y la clave **publishable** (anon). ⚠️ Nunca uses `service_role` / `sb_secret_`: la app la rechaza.
5. Pon esos datos en `lib/core/config/app_config.dart` o compílala con `--dart-define-from-file=env.json`.

> ¿Ya tenías un proyecto con las migraciones anteriores? **No** vuelvas a ejecutar `setup_completo.sql`. Para separar las granjas ejecuta, en este orden, `supabase/respaldo_antes_de_20261003.sql` (copia de seguridad en el esquema `respaldo_20261020`) y `supabase/migrations/20261003_multi_granja.sql`. Tus datos quedan juntos en la «Granja principal» y las cuentas conservan su rol.

> 🔐 **Solo un administrador.** `supabase/migrations/20261026_solo_un_administrador.sql` hace que únicamente los correos de la tabla `administradores_autorizados` puedan crear granjas; todas las demás cuentas (correo o Google) entran como operadores. Si tu proyecto ya existe, ejecútala en el **SQL Editor** (en uno nuevo ya viene en `setup_completo.sql`). Antes, cambia en ella el correo `jovmez0409@gmail.com` por el de tu cuenta. La regla vive en la base de datos, así que también protege a las versiones viejas de la app.

**Inicio de sesión con Google (una vez, en Google Cloud y Supabase):**

1. En [Google Cloud Console](https://console.cloud.google.com/apis/credentials) crea unas credenciales **ID de cliente de OAuth** de tipo **Aplicación web**. En «URI de redireccionamiento autorizados» pon `https://<tu-proyecto>.supabase.co/auth/v1/callback` (Supabase la muestra en el paso 2). Configura antes la «Pantalla de consentimiento de OAuth».
2. En Supabase: **Authentication > Sign In / Providers > Google**: actívalo y pega el **Client ID** y el **Client secret**.
3. En Supabase: **Authentication > URL Configuration > Redirect URLs**: agrega `io.supabase.porcinotech://login-callback/`.
4. Si usas la misma cuenta de correo con contraseña y con Google, Supabase las une como una sola cuenta porque Google confirma el correo.

**Correo de recuperación de contraseña (una vez, en Supabase):**

1. **Authentication > Emails > Templates > Reset Password**: reemplaza el contenido por algo como `<h2>Recupera tu contraseña</h2><p>Tu código es: <b>{{ .Token }}</b></p>` (hay una plantilla lista en `supabase/plantilla_correo_recuperar.html`).
2. **Authentication > Sign In / Providers > Email**: sube «Minimum password length» a 8 y activa «Leaked password protection» si tu plan lo permite.
3. El correo de pruebas de Supabase tiene pocos mensajes por hora. Para uso real configura un SMTP propio en **Authentication > SMTP Settings**.

</details>

<details>
<summary><b>📦 Publicar el APK en GitHub Releases</b></summary>

La app usa el identificador `mx.utvm.porcinotech` (se cambia en `android/app/build.gradle.kts`, línea `applicationId`; cámbialo **antes** de la primera publicación, porque después Android lo trata como otra app).

1. **Llave de firma** (una sola vez; guárdala, sin ella no podrás actualizar la app):
   ```powershell
   keytool -genkey -v -keystore porcinotech.jks -keyalg RSA -keysize 2048 -validity 10000 -alias porcinotech
   ```
2. **Automático con GitHub:** en *Settings > Secrets and variables > Actions* crea `ANDROID_KEYSTORE_BASE64` (el `.jks` en base64: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("porcinotech.jks"))`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` y `ANDROID_KEY_PASSWORD`. Luego sube una etiqueta nueva (por ejemplo `v1.0.2`):
   ```powershell
   git tag v1.0.2
   git push origin v1.0.2
   ```
   El flujo `.github/workflows/release.yml` construye el APK y lo adjunta al Release como `PorcinoTech.apk`.
3. **A mano:** crea `android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y `keyPassword` y ejecuta `flutter build apk --release`.

</details>

---

<div align="center">

Proyecto individual para la materia **Desarrollo Móvil Integral** · Universidad Tecnológica del Valle del Mezquital (UTVM) 🎓

Hecho con 🌱 por [Angel Jovani Benitez Mezquite](https://github.com/angel04-gifd)

</div>
