# Sonora: tablas de vida, COVID-19 y fecundidad

## Descripción

Este repositorio contiene el proyecto final de Demografía 9219, enfocado en la construcción de tablas de vida abreviadas para el estado de Sonora en los años 2010, 2019 y 2021, separadas por sexo.

El objetivo principal es estimar la esperanza de vida al nacer, comparar su evolución en el tiempo y analizar el efecto del aumento de la mortalidad durante 2021, asociado a la pandemia de COVID-19.

Además, el proyecto incluye una tabla de vida de 2019 con causa eliminada por homicidios, así como indicadores de fecundidad para estudiar la evolución reproductiva de la entidad.

## Integrantes

* Aldo Daniel Castañeda González
* Saúl Valdiviezo Velazco

## Organización del proyecto

```text
Demography_9219_Sonora/
├── README.md
├── Demography_9219_Sonora.qmd
├── Demography_9219_Sonora.pdf
├── data/
├── script/
└── output/
```

## Carpetas principales

* `data/`: contiene las bases originales utilizadas en el proyecto.
* `script/`: contiene los códigos en R para preparar datos, construir tablas de vida y generar gráficas.
* `output/`: contiene los archivos finales generados, como tablas, gráficas y archivos Excel.

Dentro de `output/` se organiza la información de la siguiente forma:

```text
output/
├── graficas/
├── tablas_vida/
├── LT_CausaEliminada.xlsx
└── TasasDeMortalidad.xlsx
```

* `graficas/`: contiene las gráficas finales del informe.
* `tablas_vida/`: contiene las tablas de vida visuales y el resumen de esperanza de vida.
* `LT_CausaEliminada.xlsx`: contiene la tabla de vida de 2019 con causa eliminada por homicidios.
* `TasasDeMortalidad.xlsx`: contiene las tasas de mortalidad calculadas.

## Fuentes de información

Los datos utilizados provienen principalmente de INEGI.

* Censo de Población y Vivienda 2010.
* Censo de Población y Vivienda 2020.
* Estadísticas de Defunciones Registradas.
* Información de nacimientos para el cálculo de indicadores de fecundidad.

Las defunciones se trabajaron considerando año de ocurrencia, sexo, edad, entidad federativa y causa de muerte cuando fue necesario.

## Metodología general

El procedimiento seguido fue:

1. Lectura y limpieza de las bases de población.
2. Agrupación de edades para tabla de vida abreviada.
3. Limpieza y organización de las defunciones.
4. Cálculo de defunciones promedio para los años de referencia.
5. Estimación de la población expuesta al riesgo mediante crecimiento exponencial.
6. Cálculo de tasas centrales de mortalidad.
7. Construcción de tablas de vida por sexo para 2010, 2019 y 2021.
8. Obtención de la esperanza de vida al nacer.
9. Construcción de la tabla de vida de 2019 con causa eliminada por homicidios.
10. Cálculo de indicadores de fecundidad: TGF, TBR y TNR.
11. Generación de gráficas, tablas e informe final.

Los años de referencia para defunciones se construyeron así:

```text
2010 = promedio de 2009, 2010 y 2011
2019 = promedio de 2018 y 2019
2021 = promedio de 2020, 2021 y 2022
```

## Scripts utilizados

El proyecto puede reproducirse corriendo los scripts en el siguiente orden:

```r
source("script/01_preparacion_datos.R")
source("script/02_tablas_vida.R")
source("script/03_visualizacion.R")
```

### `01_preparacion_datos.R`

Carga paquetes, define rutas, lee las bases de población y defunciones, limpia los datos y prepara los objetos necesarios para los cálculos posteriores.

### `02_tablas_vida.R`

Calcula la población expuesta al riesgo, las tasas centrales de mortalidad y las tablas de vida para 2010, 2019 y 2021 por sexo.

### `03_visualizacion.R`

Genera las gráficas principales, las tablas visuales y los archivos de salida utilizados en el informe.

## Resultados generados

El proyecto genera seis tablas de vida principales:

```text
2010 Hombres
2010 Mujeres
2019 Hombres
2019 Mujeres
2021 Hombres
2021 Mujeres
```

También se generan:

* resumen de esperanza de vida al nacer por sexo y año;
* gráficas de tasas centrales de mortalidad;
* gráficas de probabilidades de muerte;
* curvas de sobrevivientes;
* distribución de defunciones de la cohorte hipotética;
* comparación de esperanza de vida con causa eliminada por homicidios;
* probabilidades de muerte observadas y sin homicidios;
* indicadores de fecundidad para Sonora.

## Gráficas principales

Las gráficas del proyecto se encuentran en:

```text
output/graficas/
```

Entre las principales salidas se incluyen:

* tasas centrales de mortalidad;
* probabilidades de muerte;
* sobrevivientes de la cohorte hipotética;
* defunciones de la cohorte;
* cambio acumulado en esperanza de vida;
* esperanza de vida observada y sin homicidios;
* probabilidades de muerte con causa eliminada por sexo.

## Tablas visuales

Las tablas visuales se encuentran en:

```text
output/tablas_vida/
```

Ahí se guardan las tablas de vida por año y sexo, además del resumen de esperanza de vida al nacer.

## Informe final

El informe principal se encuentra en:

```text
Demography_9219_Sonora.qmd
```

El PDF generado corresponde a:

```text
Demography_9219_Sonora.pdf
```

El informe incluye:

* contexto demográfico de Sonora;
* diagrama de flujo del procedimiento;
* fórmulas utilizadas;
* código principal;
* tablas de vida;
* cuadro de esperanza de vida;
* análisis de causa eliminada por homicidios;
* indicadores de fecundidad;
* gráficas finales;
* análisis de resultados.

## Nota final

El repositorio está organizado para que el proyecto pueda revisarse y reproducirse desde RStudio. Los datos se encuentran en `data/`, el código en `script/` y los resultados finales en `output/`.
