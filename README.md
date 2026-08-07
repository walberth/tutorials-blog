# Coding With No Try/Catch | Demos y documentación

Repositorio base para las demos técnicas y la documentación que acompañan los
posts de [Coding With No Try/Catch](https://codingwithnotrycatch.com/).

La idea de este README es servir como portada e índice del repositorio. Cada
demo vive en su propia carpeta y mantiene su propio README con el detalle de
arquitectura, prerequisitos, setup, ejecución y troubleshooting.

## Objetivo del repositorio

Este repositorio agrupa implementaciones prácticas que respaldan artículos del
blog. Cada carpeta representa una demo autocontenida, pensada para poder:

- explicar un concepto técnico con código ejecutable,
- reproducir el escenario localmente,
- evolucionar de forma independiente del resto de demos.

## Cómo navegar este repositorio

Si llegaste desde un post del blog, entra directamente a la carpeta de la demo
correspondiente y sigue su README.

Si llegaste al repositorio primero, usa la siguiente tabla como punto de
entrada para descubrir las demos disponibles.

## Demos disponibles

| Demo | Tema | Qué muestra | Carpeta |
| --- | --- | --- | --- |
| CDC SQL Server + Kafka + Debezium | Change Data Capture con SQL Server, Kafka Connect y Debezium | Captura cambios en SQL Server y los publica en Kafka, con visualización en Kafka UI y un visor web propio | [cdc-sqlserver-kafka-debezium](./cdc-sqlserver-kafka-debezium/) |

## Demo actual destacada

### CDC SQL Server -> Kafka con Debezium

Esta demo implementa un flujo local completo de CDC usando Docker Compose.
Incluye SQL Server como origen, Kafka, Kafka Connect con Debezium, scripts de
automatización y un visor web para observar eventos en tiempo real.

Punto de entrada: [cdc-sqlserver-kafka-debezium/README.md](./cdc-sqlserver-kafka-debezium/README.md)

En esa demo encontrarás:

- infraestructura lista para levantar localmente,
- scripts para inicializar base de datos y simular cambios,
- configuración del connector de Debezium,
- un viewer web para presentar los eventos CDC.

## Estructura esperada para nuevas demos

Conforme el blog crezca, este repositorio puede sumar nuevas carpetas al mismo
nivel que la demo actual. La convención recomendada es:

```text
tutorials-blog/
├─ README.md
├─ demo-1/
│  └─ README.md
├─ demo-2/
│  └─ README.md
└─ demo-n/
	└─ README.md
```

Cada demo debería ser autocontenida y documentar como mínimo:

- objetivo de la demo,
- prerequisitos,
- pasos de ejecución,
- forma de validación,
- estructura interna,
- problemas comunes,
- relación con el post del blog.

## Criterio para este README raíz

Para evitar duplicación, este README no debe convertirse en una copia de los
README internos. Su responsabilidad es:

- describir el propósito general del repositorio,
- listar y enlazar las demos disponibles,
- ofrecer contexto suficiente para elegir a cuál entrar,
- mantener una convención simple para futuras incorporaciones.

## Cómo extenderlo con cada nuevo post

Cuando agregues una nueva demo, bastará con:

1. crear su carpeta en la raíz del repositorio,
2. añadir un README propio dentro de esa carpeta,
3. sumar una fila en la sección "Demos disponibles" de este archivo.

Con eso, el repositorio seguirá siendo fácil de navegar aunque crezca el número
de implementaciones.
