# PorcinoTech

## Configuración de acceso

No hay credenciales incluidas en el código. La app requiere un proyecto de
Supabase propio y no debe usarse una cuenta administradora compartida.

1. Crea un proyecto en Supabase y ejecuta `supabase/schema.sql` en **SQL Editor**.
   Después, en este orden, ejecuta:
   `supabase/migrations/20260928_food_ration_and_stock.sql`,
   `supabase/migrations/20260929_roles_permissions.sql`,
   `supabase/migrations/20260930_roles_crud_stages.sql`,
   `supabase/migrations/20261001_arete_unico.sql`,
   `supabase/migrations/20261002_reglas_negocio.sql` y
   `supabase/realtime.sql`.
   Las migraciones pueden volver a ejecutarse, salvo que los datos ya rompan la
   regla que crean: `20261001` falla si hay aretes repetidos y `20261002` si una
   cerda tiene dos gestaciones pendientes (el propio archivo explica cómo
   resolverlo).
2. En **Authentication > Providers > Email**, habilita el proveedor Email. Para
   desarrollo puedes desactivar **Confirm email**; en producción configura SMTP
   y mantenlo activado.
3. Copia el **Project URL** y la clave pública **anon** desde **Settings > API**
   en `env.json`. Nunca uses ni publiques la clave `service_role` en Flutter.
4. Ejecuta o compila la aplicación siempre con `env.json`:

   ```powershell
   flutter run --dart-define-from-file=env.json
   flutter build apk --release --dart-define-from-file=env.json
   ```

   El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Sin
   `--dart-define-from-file` la app se cierra al abrir.

5. Registra `TU_CORREO@ejemplo.com` en la app y ejecuta
   `supabase/assign_initial_admin.sql` en **SQL Editor** para promover esa
   cuenta. Las demás cuentas nacen con el rol `operador`. Cierra sesión y vuelve
   a entrar para ver las opciones de administrador.

Si pierdes una contraseña, restablécela desde Authentication en el panel o con
**¿Olvidaste tu contraseña?** en el login (configura la URL de redirección en
**Authentication > URL Configuration**).

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

Todos los usuarios ven los mismos datos de la granja.

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
| Etapas productivas: modificar | ✅ | ❌ (solo lectura) |
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
4. Abre **PorcinoTech**, toca registrarte con tu correo y una contraseña, e
   inicia sesión. Tu cuenta nace con el rol **operador** (ver la tabla de
   permisos). Solo el administrador puede promover a otro usuario.
5. Necesitas internet: todos los usuarios comparten los mismos datos de la
   granja en tiempo real.

## Generar un APK nuevo (administrador)

Requiere `env.json` con tu URL y clave anon de Supabase (nunca se sube al
repositorio) y haber ejecutado todas las migraciones:

```powershell
flutter build apk --release --dart-define-from-file=env.json
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.
