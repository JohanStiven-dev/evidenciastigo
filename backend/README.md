# Backend - Administrativo TIGO

Este proyecto contiene el API REST para la aplicación de gestión de actividades BTL/Trade. Está construido con Node.js, Express, y Sequelize como ORM para la base de datos.

## Flujo de Trabajo y Lógica de Negocio

La lógica principal de la aplicación gira en torno al ciclo de vida de una "Actividad", el cual es gestionado por tres roles de usuario: `Comercial`, `Productor` y `Cliente`.

### Roles de Usuario

*   **Comercial:** Responsable de crear las propuestas de actividad y de dar el cierre final una vez que las evidencias han sido aprobadas.
*   **Productor:** Responsable de la parte operativa. Define el presupuesto desglosado en "items", ejecuta la actividad y sube las evidencias.
*   **Cliente:** Responsable de la aprobación. Valida la propuesta inicial y da el visto bueno final sobre las evidencias para cerrar el ciclo.

### Ciclo de Vida de una Actividad

El estado de una actividad se define por dos campos: `status` (el estado principal de la fase) y `sub_status` (el estado específico dentro de esa fase).

**1. Fase: `Planificación`**
*   **Creación:** Un **Comercial** crea una actividad con un `valor_total`. La actividad nace en `status: Planificación` y `sub_status: Borrador`.
*   **Envío a Validación:** El **Comercial** envía la actividad a validación, cambiando su `sub_status` a `En Revisión`. En este punto, se notifica automáticamente por correo al **Cliente**.
*   **Validación Inicial (por Cliente):**
    *   **Si se RECHAZA:** El **Cliente** debe proveer un motivo. El `sub_status` cambia a `Rechazado` y se notifica por correo al **Comercial** para que realice correcciones.
    *   **Si se APRUEBA:** El `status` cambia a `Confirmada`.

**2. Fase: `Confirmada`**
*   **Planificación del Productor:** El `sub_status` es `Programada`. Se notifica por correo al **Productor** para que pueda planificar la ejecución. La actividad aparece en el calendario.
*   **Desglose de Presupuesto:** El **Productor** crea los "items" del presupuesto. La suma de los costos de estos items no puede superar el `valor_total` de la actividad (validación del lado del servidor).

**3. Fase: `En Curso`**
*   **Inicio:** El **Productor** cambia el estado a `En Ejecución`.
*   **Carga de Evidencias:** Al terminar, el **Productor** cambia el estado a `Cargando Evidencias` y debe subir al menos una foto por cada item del presupuesto.
*   **Envío a Aprobación Final:** Una vez cargadas todas las evidencias, el **Productor** cambia el `sub_status` a `Aprobación Final`. Se notifica por correo al **Cliente** y al **Comercial**.

**4. Fase: `Finalizada`**
*   **Validación Final (por Cliente):**
    *   **Si se RECHAZA:** El **Cliente** debe proveer un motivo (observación). El `sub_status` vuelve a `Cargando Evidencias` y se notifica por correo al **Productor** y al **Comercial**. El motivo queda registrado en la bitácora.
    *   **Si se APRUEBA (Visto Bueno):** El `sub_status` cambia a `Completado`. La actividad se considera un éxito.

---