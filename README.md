# DoingLio

[![Abrir DoingLio](https://img.shields.io/badge/▶%20ABRIR-DOINGLIO-ff6b35?style=for-the-badge)](https://doinglio.revalsoftia.chatgpt.site/)

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
- Web activa verificada: `https://doinglio.revalsoftia.chatgpt.site/`
- GitHub Pages objetivo: `https://duiliomf.github.io/doinglio/`
- GitHub Pages: pendiente de habilitación en el repositorio.

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
