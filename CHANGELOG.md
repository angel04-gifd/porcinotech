# Historial de versiones

Todas las versiones notables de **PorcinoTech**. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el versionamiento es [semántico](https://semver.org/lang/es/) (`MAYOR.MENOR.PARCHE`). Cada entrega importante se identifica con un tag `vX.Y.Z` y se publica como Release con su APK.

## [1.0.8] - 2026-11-04

### Agregado
- Aviso de confirmación ("¿Abrir tu galería?" / "¿Abrir la cámara?") antes de elegir la foto de perfil.

## [1.0.7] - 2026-11-04

> Antes de instalar esta versión hay que ejecutar en el SQL Editor de Supabase las migraciones `20261104_motivo_sin_corral.sql` y `20261104_foto_perfil.sql`.

### Agregado
- Un cerdo sin corral debe indicar por qué: venta, matadero, fallecimiento, cuarentena o enfermería, traslado a otra granja u otro motivo. El motivo sugiere el estado (vendido, baja o fallecido) y se muestra en la lista y en el detalle.
- Foto de perfil: se puede elegir de la galería o tomar con la cámara (JPG, PNG o WebP, hasta 2 MB), cambiar o quitar desde el perfil. Tiene prioridad sobre la foto de Google.

## [1.0.6] - 2026-11-04

### Agregado
- Menú de razas (Duroc, Yorkshire, Landrace, Hampshire, Pietrain, Criollo y Otra) en el formulario de cerdos.
- Foto de la cuenta de Google, o las iniciales si no hay foto, en el ícono de la barra superior y en el perfil.
- Convivencia de sexos: un macho no puede ir a un corral de Gestación, y se avisa cuando macho y hembra comparten corral sin una inseminación en los últimos 3 días.
- El corral es obligatorio al registrar un cerdo nuevo.

### Cambiado
- El peso debe ser mayor que 0 y de hasta 400 kg (antes 500), solo admite números y muestra un texto de ayuda.
- El nombre del cerdo no puede ser solo números ni igual al arete de otro cerdo.

### Corregido
- Formulario de cerdos: los campos ya no se montan entre sí y el botón muestra "Guardando…" en lugar de solo el círculo de carga.

## [1.0.5] - 2026-11-03

### Agregado
- Guía del flujo de trabajo en GitHub (`docs/flujo-de-trabajo.md`) y plantilla de Pull Request.
- Validación automática con `flutter analyze` y `flutter test` en cada push de rama (CI).

### Cambiado
- Tarjetas del Inicio con más jerarquía visual (icono en recuadro, cifra en negrita, etiqueta más suave). Este cambio ya estaba en `main`, pero no en el APK publicado como 1.0.4.

## [1.0.4] - 2026-11-03

### Agregado
- Cumplimiento de tiendas: eliminar cuenta, política de privacidad y términos de uso (`docs/privacidad.md`, `docs/terminos.md`).
- Aviso de gestaciones atrasadas en Inicio, marcadas en rojo cuando la fecha de parto ya venció.
- Pantallas vacías con icono en cerdos, corrales y alimentos.
- Peso de referencia según la edad en el formulario de cerdos, con confirmación al salir del rango en lechones.
- Máximo de 3 comidas al día con confirmación y lista para borrar las que sobran.
- Pruebas automáticas de reglas de comidas, peso de referencia y reglas generales de la app.

### Cambiado
- Tema visual: tarjetas planas con borde, campos rellenos y botón principal en rosa de cerdo.
- Tarjetas de Inicio con más jerarquía visual.
- Los errores se muestran siempre en español.
- El arete ya no es único por usuario, solo por granja.

### Corregido
- Coma sobrante en `supabase/setup_completo.sql`.
- Tipo de la lista de comidas registradas.

## [1.0.3] - 2026-11-02

### Agregado
- Botón de iniciar sesión con Google al inicio de la pantalla de login.

### Corregido
- Los errores se muestran como alertas claras, sin el código en crudo.

## [1.0.2] - 2026-10-27

### Agregado
- Inicio de sesión con Google.
- Control para que solo un administrador autorizado tenga ese rol.
- Zona de testers, formulario de observaciones y README separado para usuarios, testers y desarrolladores.
- Publicación del APK también en el repositorio público de descargas.

### Corregido
- Las listas ya no dependen solo de Realtime.
- Observaciones reportadas por los testers.

## [1.0.1] - 2026-10-21

### Agregado
- Multi granja, roles por cuenta y datos de demostración.
- Datos personales, ojo para ver la contraseña y recuperación de contraseña con código.
- Logo e iconos de la app.
- Identificador de la app, firma y flujo de GitHub Actions para publicar el APK.

### Cambiado
- Versiones de dependencias actualizadas.

## [1.0.0] - 2026-10-15

### Agregado
- Esquema de Supabase, roles, etapas productivas y reglas de negocio.
- Arranque, enrutador, inicio de sesión y perfil.
- Gestión de cerdos y corrales con validación de capacidad y peso.
- Alimentos, consumo con stock y ración por etapa productiva.
- Inseminaciones, calendario de partos y gestación fallida.
- Panel de control con métricas y gráfica de consumo.
- Pruebas de fecha de parto, arete, gestación, peso y capacidad.

[1.0.8]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.8
[1.0.7]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.7
[1.0.6]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.6
[1.0.5]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.5
[1.0.4]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.4
[1.0.3]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.3
[1.0.2]: https://github.com/angel04-gifd/porcinotech/compare/v1.0.1...7b022ab
[1.0.1]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.1
[1.0.0]: https://github.com/angel04-gifd/porcinotech/releases/tag/v1.0.0
