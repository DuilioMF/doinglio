# Protocolo de actualizaciones y versionado DoingLio
**Contrato operativo (29/09/2026).** Una tarjeta operativa identificable en Trello inicia cada cambio. La tarjeta índice del proyecto padre no sustituye las tarjetas de entrega.

## Fuentes de verdad
- Trello: pedido, criterios de aceptación, estado y enlace a PR.
- GitHub `main`: código fuente y archivo `BUILD` de DoingLio; cada hijo usa su propio `VERSION`. Una etiqueta compuesta D.C/D.R se calcula, no se guarda fija.
- GitHub Actions: compuertas de pruebas y evidencia de despliegue.
- Sitio publicado: fuente observable de la versión que recibe el usuario, nunca inferida solo de main.
- Supabase: registro de versiones y eventos con SHA, resultado y trazabilidad; la sincronización llega por n8n.

## Pasos obligatorios
1. Leer tarjeta Trello y estado real de los repositorios y sitios. Si existen cambios en curso, no duplicarlos.
2. Crear rama y PR enlazados con la tarjeta. Guardar SHA de base para rollback.
3. Realizar los cambios pedidos, probarlos y actualizar BUILD una sola vez cuando hay una entrega nueva de DoingLio. No aumentar C o R al cambiar solo D.
4. En PR, pasar tests de versiones y smoke de escritorio. Si cualquier test falla, reparar y repetir; no publicar todavía.
5. En el merge a main, Actions debe volver a ejecutar ambos controles antes de publicar Pages.
6. Tras desplegar, comprobar por HTTP que `https://doinglio.revalsoftia.com.ar/BUILD` coincida con el BUILD del SHA desplegado. Si no coincide, fallo de release; no declarar éxito.
7. Solo el workflow de despliegue exitoso habilita el workflow de sincronización GitHub→n8n→Trello/Supabase. Revalidar main SHA y BUILD servido en la web antes de enviar el evento.
8. Conciliar la versión y SHA guardados en Supabase con GitHub y la tarjeta. Un HTTP 200 del webhook NO prueba por sí solo que la escritura en Supabase y Trello haya ocurrido. Ante discrepancias, registrar incidente, dejar tarjeta EN PRUEBA y reparar la sincronización.
9. Si se afectan instalaciones locales o SQL, verificar por separado el conector real y la funcionalidad en la PC. La CI no certifica conexiones físicas ni credenciales.
10. Cerrar la tarjeta operativa solo cuando las evidencias y criterios de aceptación estén completos. Mantener la tarjeta índice del proyecto padre abierta.

## Evidencias mínimas
Tarjeta, PR, SHA anterior y actual, BUILD, ejecuciones verdes del test Windows/versiones, URL de Pages verificado, evento en Supabase y evidencia de sincronización Trello. Adjuntar prueba del conector cuando corresponda.

## Estados
`En ejecución` → `En prueba` → `Verificado y cerrado`. Fallos se registran en `En prueba` con responsable y siguiente acción. No editar directamente una versión en Supabase para ocultar un fallo de sincronización.

## Rollback
Revertir el PR / commit con trazabilidad y volver a ejecutar las compuertas. Si hay una nueva publicación restauradora, registrar explícitamente la versión que se sirve sin reescribir el historial.

## Entregas coordinadas padre e hijo (ejemplo D33.C95)
1. Crear una única tarjeta de release con dos PR independientes y los SHA previos de cada proyecto.
2. Publicar y comprobar **primero** el especialista que cambia (Capitán C95): fuente VERSION, cinco HTML, siete ventanas, recursos CSS/JS y paquete del conector. La CI de PR no reemplaza la prueba HTTP ni la conexión física.
3. Tras Pages y VERSION público coincidentes, ejecutar la sincronización GitHub→n8n→Trello/Supabase del especialista. Registrar incidentes de entrega en la misma tarjeta.
4. Publicar y comprobar **después** DoingLio D33: fuente BUILD, prueba Windows/ventanas y BUILD del dominio real.
5. DoingLio compone el par con la VERSION **realmente servida o instalada** del hijo. Nunca fijar C95 ni R4 manualmente en el padre. La actualización de Capitán no altera la VERSION de Rubén.
6. Conciliar las tarjetas índice de cada proyecto y la tarjeta operativa contra main, URL publicada y las evidencias de Actions. Mostrar claramente "pendiente de validación" si la instalación local o SQL no pudieron verificarse.
7. Para instalaciones en PC, el launcher descarga el especialista y copia su VERSION al conector sin tocar credenciales. Antes de marcar "conectado", la respuesta /health debe informar la VERSION exacta, y deben validarse las consultas SQL funcionales si forman parte de la entrega.
