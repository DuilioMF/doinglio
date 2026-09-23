# Registro universal de conectores

Fuente operativa: Memoria Duilio / Supabase `pddsehshgfynpmibjqhj`.

## Objetivo

Permitir que DoingLio y los proyectos relacionados registren conectores e instancias sin depender de nombres fijos en el código.

## Proveedores soportados

- GitHub
- Supabase
- Trello
- Notion
- n8n

Cada proveedor admite múltiples instancias mediante `provider + instance_key`.

## Flujo universal

1. Un conector o sistema detecta un proyecto/recurso.
2. Envía el evento al intake universal de Memoria Duilio.
3. Supabase resuelve el proyecto canónico.
4. Se crea o actualiza el vínculo proyecto ↔ instancia ↔ recurso.
5. Los índices únicos evitan duplicados.
6. Los trabajos de aprovisionamiento faltantes se encolan sólo cuando corresponde.
7. GitHub mantiene la autoridad de versión para los proyectos versionados.

## Contrato de entrada

Workflow n8n: `Memoria Duilio — Alta universal de proyectos y conectores`

Webhook: `memoria-universal-project-intake-v1`

Acciones:
- `register_connector`
- `project_event`

## Regla de extensión

Agregar otra cuenta/proyecto de Supabase, Trello, Notion, n8n o GitHub no requiere modificar el núcleo: se registra una nueva instancia y luego se vinculan los recursos correspondientes.

## Verificación 23/09/2026

- Segundo Supabase registrado sin reemplazar el principal.
- Registro repetido devolvió la misma instancia.
- Evento repetido de DoingLio produjo 1 solo intake, 1 solo proyecto y 1 solo vínculo GitHub.
- Los 7 proyectos operativos actuales están presentes en el registro universal.

Este archivo existe también como prueba de push a `main` para disparar el sincronizador de versiones GitHub → n8n → Supabase/Trello.
