# Frontend - Administrativo TIGO

Este proyecto es la aplicación cliente para la gestión de actividades BTL/Trade, construida con Flutter.

## Estado Actual del Proyecto

**ADVERTENCIA: El proyecto actualmente no compila.**

Durante una refactorización mayor para implementar un nuevo sistema de estados, se introdujeron errores en las vistas de la aplicación, principalmente en `lib/activity_detail_view.dart`. Los modelos de datos (`lib/models/`) y los servicios de API (`lib/services/api_service.dart`) sí fueron actualizados y están sincronizados con el backend.

## Flujo de Trabajo

La aplicación debe implementar el flujo de trabajo detallado en el `README.md` del proyecto backend. Esto implica una UI dinámica que presenta diferentes acciones y vistas basadas en el rol del usuario logueado (`Comercial`, `Productor`, `Cliente`).

## Tareas Pendientes (QUÉ FALTA)

Para que la aplicación sea completamente funcional y compile correctamente, se deben realizar las siguientes tareas:

1.  **Corregir Errores de Compilación:**
    *   La tarea prioritaria es ejecutar `flutter analyze` y solucionar todos los errores reportados, que se concentran en `lib/activity_detail_view.dart`. Los errores están relacionados con dependencias que no se usan correctamente (`image_picker`, `url_launcher`) y métodos que fueron eliminados o renombrados durante la refactorización.

2.  **Construir UI para el Productor:**
    *   Crear una interfaz de usuario dedicada para que el **Productor** pueda gestionar el desglose del presupuesto de una actividad (añadir, editar y eliminar "Items").
    *   Implementar la UI para la **carga de múltiples evidencias (fotos) por cada item** del presupuesto.

3.  **Construir UI para el Cliente:**
    *   Diseñar una vista clara y funcional para que el **Cliente** pueda revisar las evidencias de cada item antes de dar su "visto bueno" o rechazar la entrega final.
    *   Implementar un diálogo o campo de texto para que el Cliente pueda escribir el **motivo del rechazo (observación)**.

4.  **Refinar la Lógica de Roles en la UI:**
    *   Asegurarse de que los botones de acción (ej. "Editar", "Cambiar Estado") en `actividades_view.dart` y `activity_detail_view.dart` aparezcan o se deshabiliten correctamente según el rol del usuario logueado y el estado/sub-estado actual de la actividad.

5.  **Limpieza de Código:**
    *   Resolver las advertencias menores (`info`) reportadas por `flutter analyze` para mejorar la calidad y el rendimiento del código (ej. `prefer_const_constructors`).
---
