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
