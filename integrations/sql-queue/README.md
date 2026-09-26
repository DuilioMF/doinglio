# DoingLio → WhatsApp → SQL Server sin instalar nuevos programas en Windows
Estado: backend y worker versionados. Activación y E2E pendientes de configuración.
## Componentes publicados
- Supabase proyecto n8n: Edge Function doinglio-sql-queue. Custom authentication por x-doinglio-token; verify_jwt=false SOLO porque comprueba dos tokens privados en cada petición y no permite acceso anónimo.
- Tabla existente public.doinglio_sql_question_queue. No se borró ni reemplazó. Función atomic claim public.doinglio_sql_claim_next() ejecutable SOLO por service_role.
- Conector existente: bridge/doinglio_sql_queue_worker.ps1 (PowerShell ya instalado), lanzado y registrado por CAPITAN_RODOLFO.bat. No expone SQL Server ni el puerto 8787.
- Workflow n8n para importar: DoingLio_Capitan_SQL_Supabase_n8n_v2.json (archivo de entrega del proyecto).
## Configuración indispensable (no poner valores en Git ni en chats)
1. En Supabase Dashboard, Edge Functions / Secrets del proyecto n8n, configurar dos valores aleatorios de al menos 32 bytes distintos:
   DOINGLIO_SQL_N8N_TOKEN y DOINGLIO_SQL_WORKER_TOKEN. No reutilizar credenciales de WhatsApp o SQL.
2. En n8n, importar la versión v2 como un NUEVO subworkflow. En ambos HTTP Request, seleccionar la misma credencial Header Auth: nombre x-doinglio-token y valor DOINGLIO_SQL_N8N_TOKEN. No cambiar el webhook actual.
3. En Windows, ejecutar el instalador/actualizador ya existente CAPITAN_RODOLFO.bat desde la rama main (revisar antes de ejecutarlo). Actualiza el servicio actual, descarga el worker y crea la tarea CapitanRodolfoSqlQueue ONLOGON con la misma cuenta del usuario.
4. En Windows ejecutar bridge/configurar_cola_sql.ps1 para guardar DOINGLIO_SQL_WORKER_TOKEN protegido mediante DPAPI. Hacerlo CON EL MISMO usuario Windows que inicia el servicio; nunca pegar claves en un script.
5. Antes de habilitar un teléfono, ejecutar localmente GET http://127.0.0.1:8787/api/station/ids para leer IDs reales; configurar public.doinglio_phone_access con specialist_key='capitan-rodolfo', enabled=true, pago o exención autorizados y station_ids reales. No habilitar por defecto a otros teléfonos.
6. En el AI Agent WhatsApp conectar una Call n8n Workflow Tool al subworkflow nuevo, pasar wa_id, consulta='circuito_estacion', idEstacion autorizado, request_id ID original de WhatsApp y question. Conservar captura, salida y auditoría actuales.
7. E2E: probar autorización negativa; consulta estación real; SQL detenido; cola con duplicado wa_message_id; confirmar respuesta real y registro outbound Meta. Nunca marcar como terminado con sólo una prueba local.
## Riesgos y limitaciones
- La consulta inicial solamente acepta 'station_circuit', con identificador de estación numérico. El worker llama a POST /api/station/circuit en el localhost del equipo, NO ejecuta SQL arbitrario.
- La salida inicial contiene conteos provenientes del circuito SQL, no todos los importes/detalles. Extender el contrato con validación de privacidad si más adelante se requieren cobros.
- La función falla con 503 hasta que se configuren sus secretos y los permisos de teléfono/estación. No compartir las claves ni dar service_role a n8n.
- PowerShell programado ONLOGON necesita que el usuario Windows inicie sesión y el conector SQL restaure su perfil. El sistema no funciona con la PC apagada.
- Si la función se ejecuta sin conexion a SQL, la consulta queda fallida con mensaje genérico; no se inventan datos ni se afirma entrega por WhatsApp.
- Los requests procesados expiran en la experiencia síncrona de n8n a ~45 segundos, pero la cola conserva el estado real; futura mejora: callback outbound diferido.
## Rollback
- Desvincular la herramienta nueva en n8n y apagar su subworkflow (sin modificar WhatsApp).
- Detener la tarea CapitanRodolfoSqlQueue; el conector SQL tradicional permanece independiente.
- No borrar tablas/auditorías para revertir.
