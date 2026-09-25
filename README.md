# DoingLio

<p align="center"><img src="brain-davinci.svg" width="86" alt="Icono cerebro Da Vinci"></p>

[![Ver Trello](https://img.shields.io/badge/VER-TRELLO-0052CC?style=for-the-badge)](https://trello.com/c/BE027nnM)
[![Abrir DoingLio](https://img.shields.io/badge/▶%20ABRIR-DOINGLIO-ff6b35?style=for-the-badge)](https://duiliomf.github.io/doinglio/)
[![Capitán Rodolfo](https://img.shields.io/badge/ABRIR-CAPITÁN%20RODOLFO-c8793f?style=for-the-badge)](https://duiliomf.github.io/capitan-rodolfo/)
[![Ruben](https://img.shields.io/badge/ABRIR-RUBEN-54bfc3?style=for-the-badge)](https://duiliomf.github.io/ruben/)

## Qué es

Cuaderno Maestro de DoingLio. Es la puerta de entrada general a los especialistas.

## Rol en DoingLio

- **DoingLio**: entrada general.
- **Capitán Rodolfo**: especialista independiente.
- **Ruben**: especialista independiente.
- DoingLio deriva a cada especialista; no mezcla su código interno.

## Estado

- Repositorio: `DuilioMF/doinglio`
- Rama principal: `main`
- Web GitHub Pages: `https://duiliomf.github.io/doinglio/`
- GitHub Pages: habilitado y publicado.

## Conexión

DoingLio no se conecta directamente a SQL Server ni PostgreSQL. Cada especialista administra su propia conexión.

## Archivos principales

- `index.html`: Cuaderno Maestro.
- `BUILD`: número interno de build.
- `.github/workflows/pages.yml`: despliegue preparado para GitHub Pages.

## Seguridad

- No guardar credenciales ni secretos en el repositorio.
- Las conexiones a datos pertenecen a cada especialista.

## Versionado

Cada cambio debe quedar en un commit recuperable antes de publicar. Conservar rollback.


## Publicación vigente — 22/09/2026

GitHub es la fuente de código y GitHub Pages publica `main`. No usar copias de Sites como origen ni destino de navegación. Cada cambio se integra por PR y conserva su commit para rollback. Tema claro/oscuro compartido entre páginas; control arriba y regreso debajo.

## Cierre y build del escritorio (D28)

- El reloj de apertura muestra D·NN usando el último BUILD descargado; el lanzador actualiza el archivo `C:\Sistemas\DoingLioLauncher\last_build.txt` al instalar la nueva copia.
- La X superior izquierda del reloj cancela la apertura; el lanzador respeta `cancel.flag` antes de iniciar SQL o abrir el navegador.
- El servidor local inyecta automáticamente `doinglio-window.js` en **todas** las páginas HTML: Cuaderno Maestro, Capitán Rodolfo, Ruben y futuros especialistas. Comparten una X a la izquierda.
- Al pulsar X, solo se cierra la ventana del perfil exclusivo de DoingLio y termina el servidor web de esa sesión; el conector SQL residente y los navegadores personales no se detienen.
- Cada especialista sigue teniendo su versión independiente. Los sitios públicos abiertos como pestañas normales no pueden ni deben cerrar el navegador del usuario.

## D29 — etiqueta de versión visible
El build de DoingLio se lee del archivo `BUILD` y aparece debajo del nombre, separado de los controles de la derecha. En el reloj de apertura queda arriba a la izquierda, junto a la X. El lanzador adelanta la lectura de BUILD para actualizar la etiqueta aun durante la apertura anterior; el nuevo estilo del reloj aparece tras actualizar su archivo local.

## D30 — diagnóstico real del conector SQL
El proxy usa el puerto registrado por el conector y todos los puertos de reserva. Una respuesta de versión diferente se informa como incompatibilidad, no como caída de SQL Server. Diagnóstico: `/_doinglio_diagnostic`; conserva credenciales. El servidor PowerShell utiliza UTF-8 con BOM para evitar caracteres incorrectos en Windows PowerShell 5.1. Verificar en la PC antes de marcar la conexión real como probada.
