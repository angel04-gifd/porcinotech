# 🧪 Observaciones de Julio10Mon

> Este es **tu apartado**. Aquí dejas tus comentarios sobre PorcinoTech.
> Recuerda: el repositorio es público, así que **no escribas contraseñas ni datos personales**.

**Tester:** [@Julio10Mon](https://github.com/Julio10Mon)

## 📱 Mi prueba

| Dato | Respuesta |
|---|---|
| Celular y modelo | Samsung Galaxy S24 Ultra |
| Versión de Android | 16 |
| Versión de la app (ver en Releases) | |
| Rol con el que probé | Administrador |

## 📝 Mis observaciones

Agrega una fila por cada observación. Tipos: 🐞 Error · 💡 Sugerencia · 🎨 Diseño · ❓ Duda · 👏 Me gustó

| # | Fecha | Parte de la app | Tipo | ¿Qué pasó o qué propones? | Estado |
|---|---|---|---|---|---|
| 1 | 22/10/2026 | Cerdos | 🐞 Error | Al guardar un cerdo aparece "Cerdo registrado con arete 0001", pero la lista sigue diciendo "No hay cerdos registrados" y en Inicio marca 0 cerdos activos, aunque cambie de pestaña. El segundo cerdo recibió el arete 0002, así que parece que sí se guardan pero no se muestran. | 🔧 En revisión |
| 2 | 22/10/2026 | Alimento | 🐞 Error | Pasa lo mismo con los alimentos: se guardan, pero la lista sigue en "No hay alimentos registrados" y el balance de alimento marca 0.0 kg. | 🔧 En revisión |
| 3 | 22/10/2026 | Partos | 🐞 Error | No puedo registrar inseminaciones: dice "No hay cerdas activas" aunque registré una hembra con fecha de nacimiento. Parece consecuencia del error 1. | 🔧 En revisión |
| 4 | 22/10/2026 | Inicio de sesión | 💡 Sugerencia | No hay opción para iniciar sesión con Google. Sería más rápido entrar con la cuenta de Google que crear una cuenta con correo y contraseña. | 🔧 En revisión |
| 5 | 22/10/2026 | General | 🎨 Diseño | Mejorar el diseño en general. Por ejemplo: las pantallas vacías solo muestran un texto centrado (sería mejor una ilustración y un botón para agregar el primer registro), el login se ve muy simple y a las tarjetas de Inicio les falta jerarquía visual. | ⏸️ Pendiente |
| 6 | 22/10/2026 | Inicio de sesión / Recuperar contraseña | 🎨 Diseño | Algunos textos están en inglés: el error "Invalid login credentials" y el asunto del correo "Reset your password". El resto de la app está en español. | 🔧 En revisión |
| 7 | 22/10/2026 | Cerdos | 💡 Sugerencia | La app acepta datos poco realistas, como un cerdo con 6 días de nacido que pesa 77 kg. Convendría validar el peso según la edad o al menos mostrar un aviso. | 🔧 En revisión |
| 8 | 22/10/2026 | Cerdos | 💡 Sugerencia | En "Nuevo cerdo" el arete automático muestra 0001 aunque ese número ya existe; al guardar se asigna el 0002. Debería mostrar el número que realmente se va a asignar. | 🔧 En revisión |
| 9 | 22/10/2026 | Partos | 💡 Sugerencia | El botón "Guardar inseminación" está activo aunque no haya cerdas disponibles, y solo después avisa "Selecciona la cerda y la fecha de monta". Sería más claro deshabilitarlo. | 🔧 En revisión |
| 10 | 22/10/2026 | Alimento | 💡 Sugerencia | El campo "Costo por kg" acepta valores como "010". Convendría limpiar los ceros a la izquierda. | 🔧 En revisión |
| 11 | 22/10/2026 | Inicio | 💡 Sugerencia | La tarjeta del clima vuelve a mostrar "Consultando el clima…" cada vez que regreso a Inicio. Podría guardar el último dato por unos minutos. | 🔧 En revisión |
| 12 | 22/10/2026 | Cuenta | 💡 Sugerencia | "Cerrar sesión" sale de inmediato, sin pedir confirmación. | 🔧 En revisión |
| 13 | 22/10/2026 | Recuperar contraseña | 👏 Me gustó | El flujo funcionó completo: llegó el código al correo, cambié la contraseña y entré sin problemas. | 🟡 Nueva |
| 14 | 22/10/2026 | Cuenta | 👏 Me gustó | La sección de la granja es clara: código para invitar operadores, equipo y explicación de los permisos del administrador. | 🟡 Nueva |

## 💬 Comentario general

PorcinoTech tiene buenas ideas: el resumen de la granja, el calendario de partos, el balance de alimento según la etapa y el manejo de equipo con roles. La recuperación de contraseña funcionó bien. Sin embargo, por ahora el error más importante impide usarla: los cerdos y alimentos se guardan pero no aparecen, y por eso tampoco funcionan los partos ni el resumen. Si se corrige eso, se agrega el inicio de sesión con Google y se mejora el diseño, la app puede ser muy útil para administrar una granja.

---

**Cómo editar este archivo:** pulsa el icono del lápiz ✏️ (arriba a la derecha de esta página), escribe tus observaciones y baja a **Commit changes**. Solo edita **tu** archivo.

Estados que pondré yo: 🟡 Nueva · 🔧 En revisión · ✅ Resuelta · ⏸️ Pendiente
