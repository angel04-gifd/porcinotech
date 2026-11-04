# Flujo de trabajo en GitHub

Guía de cómo se versiona **PorcinoTech**. Aunque el proyecto lo desarrolla una sola persona, se trabaja con un flujo simplificado para mantener un historial claro, probar los cambios antes de integrarlos y poder recuperar versiones anteriores.

El flujo se basa en `main` y ramas de trabajo por funcionalidad.

## 1. Esquema del flujo

1. **Actualizar `main`:** partir de una versión estable.
2. **Crear una rama** por funcionalidad o tarea.
3. **Desarrollar y probar:** hacer commits pequeños.
4. **Subir la rama a GitHub** (`git push`).
5. **Integrar en `main`:** localmente con `merge --no-ff` después de validar (Pull Request opcional).
6. **Publicar una versión estable:** crear un tag y un Release cuando corresponda.

## 2. Ramas

| Rama | Uso | Ejemplo |
|---|---|---|
| `main` | Estable y funcional. Nunca se trabaja directo sobre ella. | `main` |
| `feature/*` | Una funcionalidad nueva. | `feature/eliminar-cuenta` |
| `fix/*` | Corrección de un error. | `fix/listas-sin-realtime` |
| `docs/*` | Cambios solo de documentación. | `docs/flujo-de-trabajo` |
| `chore/*` | Mantenimiento, versión, dependencias. | `chore/version-1.0.5` |
| `ci/*` | Cambios en las automatizaciones de GitHub Actions. | `ci/validar-pull-requests` |

Las ramas ya integradas **se conservan en GitHub** como respaldo y evidencia del historial. Solo se elimina la copia local.

## 3. Comandos recomendados

Ciclo de trabajo para cada funcionalidad:

```bash
# 1. Actualizar la rama principal
git switch main
git pull origin main

# 2. Crear una rama para la funcionalidad
git switch -c feature/eliminar-cuenta

# 3. Desarrollar y guardar los cambios
git add .
git commit -m "feat: agregar eliminar cuenta"

# 4. Subir la rama a GitHub
git push -u origin feature/eliminar-cuenta
```

Después se revisan los cambios y las pruebas (`flutter analyze` y `flutter test`). Si todo funciona, se integra la rama:

```bash
git switch main
git pull origin main
git merge --no-ff feature/eliminar-cuenta
git push origin main

# 5. Eliminar la rama local
git branch -d feature/eliminar-cuenta
```

Si se trabaja con un **Pull Request** (opcional), la integración se puede hacer directamente desde GitHub con **Create a merge commit**, que equivale a `--no-ff`, en lugar de ejecutar el merge local.

## 4. Mensajes de commit

Frecuentes, pequeños y descriptivos, con un prefijo que indica el tipo de cambio:

| Prefijo | Significado |
|---|---|
| `feat:` | Funcionalidad nueva. |
| `fix:` | Corrección de un error. |
| `docs:` | Documentación. |
| `test:` | Pruebas. |
| `chore:` | Mantenimiento, versión, dependencias. |
| `ci:` | Automatizaciones de GitHub Actions. |

## 5. Versiones y Releases

- Se usa [versionamiento semántico](https://semver.org/lang/es/): `MAYOR.MENOR.PARCHE`.
- Cada entrega importante se identifica con un **tag** `vX.Y.Z` sobre `main`.
- Al subir el tag, el flujo `.github/workflows/release.yml` construye el APK y lo publica en **Releases**.
- Cada versión se anota en el [CHANGELOG](../CHANGELOG.md) y en `pubspec.yaml` (campo `version`).

```bash
git switch main
git pull origin main
git tag -a v1.0.5 -m "v1.0.5: descripción breve"
git push origin v1.0.5
```

## 6. Configuración mínima recomendada

| Elemento | Recomendación |
|---|---|
| Rama principal | `main`, estable y funcional. |
| Ramas de trabajo | Una por funcionalidad o tarea relevante. |
| Commits | Frecuentes, pequeños y descriptivos. |
| Pruebas | `flutter analyze` y `flutter test` antes de integrar los cambios. |
| Respaldo | Subir regularmente las ramas a GitHub. |
| Versiones | Utilizar tags para identificar entregas importantes. |
| Seguridad | Excluir `env.json`, `key.properties`, `*.jks` y cualquier secreto. |

## 7. ¿Siempre hay que crear ramas?

No. En cambios mínimos se puede trabajar directo sobre `main`. En este proyecto se usan ramas siempre que se trate de funcionalidades independientes, cambios importantes en la arquitectura, correcciones que puedan afectar el funcionamiento o entregas que requieran evidencia de buenas prácticas.
