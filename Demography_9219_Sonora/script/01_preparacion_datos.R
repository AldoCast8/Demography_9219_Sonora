# ============================================================
# 01_preparacion_datos.R
# Proyecto de tablas de vida: Sonora
# Configuración inicial, población y defunciones
# ============================================================

rm(list = ls())

# Paquetes

paquetes <- c(
  "data.table",
  "readxl",
  "dplyr",
  "stringr",
  "tidyr",
  "ggplot2",
  "knitr"
)

faltantes <- paquetes[!paquetes %in% installed.packages()[, "Package"]]

if (length(faltantes) > 0) {
  install.packages(faltantes, dependencies = TRUE)
}

invisible(lapply(paquetes, library, character.only = TRUE))

# Configuración general

entidad <- "Sonora"

anios_objetivo <- c(2010, 2019, 2021)

anios_def_base <- c(
  2009, 2010, 2011,
  2018, 2019,
  2020, 2021, 2022
)

raiz_tabla <- 100000

ruta_data <- "data/"
ruta_script <- "script/"
ruta_output <- "output/"

if (!dir.exists(ruta_output)) {
  dir.create(ruta_output)
}

# Archivos de entrada

archivo_pob_2010 <- file.path(ruta_data, "inegi_censo_2010.xlsx")
archivo_pob_2020 <- file.path(ruta_data, "inegi_censo_2020.xlsx")
archivo_def <- file.path(ruta_data, "inegi_defunciones.xlsx")

# Funciones auxiliares

num_limpio <- function(x) {
  x <- as.character(x)
  x <- gsub(",", "", x)
  x <- gsub('"', "", x)
  x <- trimws(x)
  as.numeric(x)
}

edad_inicio <- function(x) {
  x <- str_trim(as.character(x))
  
  case_when(
    # Grupo de menores de 1 año
    str_detect(x, "Menores de 1") | str_detect(x, "^0 A") ~ 0,
    
    # Grupos quinquenales
    str_detect(x, "1-4|1 a 4") ~ 1,
    str_detect(x, "5 a 9|5-9") ~ 5,
    str_detect(x, "10 a 14|10-14") ~ 10,
    str_detect(x, "15 a 19|15-19") ~ 15,
    str_detect(x, "20 a 24|20-24") ~ 20,
    str_detect(x, "25 a 29|25-29") ~ 25,
    str_detect(x, "30 a 34|30-34") ~ 30,
    str_detect(x, "35 a 39|35-39") ~ 35,
    str_detect(x, "40 a 44|40-44") ~ 40,
    str_detect(x, "45 a 49|45-49") ~ 45,
    str_detect(x, "50 a 54|50-54") ~ 50,
    str_detect(x, "55 a 59|55-59") ~ 55,
    str_detect(x, "60 a 64|60-64") ~ 60,
    str_detect(x, "65 a 69|65-69") ~ 65,
    str_detect(x, "70 a 74|70-74") ~ 70,
    str_detect(x, "75 a 79|75-79") ~ 75,
    str_detect(x, "80 a 84|80-84") ~ 80,
    str_detect(x, "85") ~ 85,
    
    # Edades simples 1, 2, 3 y 4 años
    str_detect(x, "^1 A") ~ 1,
    str_detect(x, "^2 A") ~ 1,
    str_detect(x, "^3 A") ~ 1,
    str_detect(x, "^4 A") ~ 1,
    
    TRUE ~ NA_real_
  )
}

prorratear_valor <- function(valores, monto_no_esp) {
  
  total_conocido <- sum(valores, na.rm = TRUE)
  
  if (is.na(total_conocido) || total_conocido == 0) {
    return(valores)
  }
  
  valores + (valores / total_conocido) * monto_no_esp
}

# 1. POBLACIÓN

leer_poblacion <- function(archivo, anio_censo) {
  
  pob <- read_excel(archivo)
  setDT(pob)
  
  # Se espera una tabla con 4 columnas:
  # edad | total | hombre(s) | mujer(es)
  pob <- pob[, 1:4, with = FALSE]
  setnames(pob, c("edad_txt", "total", "hombres", "mujeres"))
  
  pob[, edad_txt := str_trim(as.character(edad_txt))]
  pob[, total := num_limpio(total)]
  pob[, hombres := num_limpio(hombres)]
  pob[, mujeres := num_limpio(mujeres)]
  
  total_original <- pob[edad_txt == "Total"]
  
  sin_edad <- pob[str_detect(edad_txt, "No especificado")]
  
  if (nrow(sin_edad) == 0) {
    sin_edad <- data.table(total = 0, hombres = 0, mujeres = 0)
  }
  
  pob <- pob[
    !edad_txt %in% c("Total", "De 0 a 4 años", "De 0 a 4 a?os") &
      !str_detect(edad_txt, "No especificado")
  ]
  
  pob[, edad := edad_inicio(edad_txt)]
  
  pob <- pob[
    !is.na(edad),
    .(
      hombres = sum(hombres, na.rm = TRUE),
      mujeres = sum(mujeres, na.rm = TRUE)
    ),
    by = edad
  ]
  
  # Prorrateo de población con edad no especificada
  pob[, hombres := prorratear_valor(hombres, sin_edad$hombres)]
  pob[, mujeres := prorratear_valor(mujeres, sin_edad$mujeres)]
  
  pob_larga <- melt(
    pob,
    id.vars = "edad",
    measure.vars = c("hombres", "mujeres"),
    variable.name = "sexo",
    value.name = "poblacion"
  )
  
  pob_larga[, sexo := ifelse(sexo == "hombres", "Hombres", "Mujeres")]
  pob_larga[, anio := anio_censo]
  
  pob_larga <- pob_larga[, .(anio, sexo, edad, poblacion)]
  setorder(pob_larga, anio, sexo, edad)
  
  revision <- pob_larga[
    ,
    .(poblacion_total = sum(poblacion, na.rm = TRUE)),
    by = sexo
  ]
  
  revision_original <- data.table(
    sexo = c("Hombres", "Mujeres"),
    total_original = c(total_original$hombres, total_original$mujeres)
  )
  
  revision <- merge(revision, revision_original, by = "sexo")
  revision[, diferencia := poblacion_total - total_original]
  
  print(paste("Revisión población", anio_censo))
  print(revision)
  
  return(pob_larga)
}

pob_2010 <- leer_poblacion(archivo_pob_2010, 2010)
pob_2020 <- leer_poblacion(archivo_pob_2020, 2020)

poblacion <- rbind(pob_2010, pob_2020)

# 2. DEFUNCIONES

def_raw <- read_excel(archivo_def)
setDT(def_raw)

# Las columnas son:
# x | reg | ocu | tot | h | m | ne
setnames(
  def_raw,
  old = names(def_raw)[1:7],
  new = c("edad_txt", "anio_registro", "anio_ocurrencia",
          "total", "hombres", "mujeres", "sexo_no_esp")
)

def_raw[, edad_txt := str_trim(as.character(edad_txt))]
def_raw[, anio_ocurrencia := str_trim(as.character(anio_ocurrencia))]

def_raw[, total := num_limpio(total)]
def_raw[, hombres := num_limpio(hombres)]
def_raw[, mujeres := num_limpio(mujeres)]
def_raw[, sexo_no_esp := num_limpio(sexo_no_esp)]

def_raw[is.na(total), total := 0]
def_raw[is.na(hombres), hombres := 0]
def_raw[is.na(mujeres), mujeres := 0]
def_raw[is.na(sexo_no_esp), sexo_no_esp := 0]

# Quitar totales y años de ocurrencia no especificados
def_raw <- def_raw[
  edad_txt != "Total" &
    anio_ocurrencia != "Total" &
    anio_ocurrencia != "No especificado"
]

def_raw[, anio_ocurrencia := as.numeric(anio_ocurrencia)]

def_raw <- def_raw[
  anio_ocurrencia %in% anios_def_base
]

def_raw[, edad := edad_inicio(edad_txt)]

# Guardar edad no especificada por separado
def_edad_no_esp <- def_raw[is.na(edad)]

# Trabajar solo con edades válidas
def_raw <- def_raw[!is.na(edad)]

# Agrupar ignorando año de registro
def_agrupada <- def_raw[
  ,
  .(
    total = sum(total, na.rm = TRUE),
    hombres = sum(hombres, na.rm = TRUE),
    mujeres = sum(mujeres, na.rm = TRUE),
    sexo_no_esp = sum(sexo_no_esp, na.rm = TRUE)
  ),
  by = .(anio_ocurrencia, edad)
]

# Prorrateo del sexo no especificado

def_agrupada[, sexo_conocido := hombres + mujeres]

def_agrupada[, prop_h := fifelse(sexo_conocido > 0,
                                 hombres / sexo_conocido,
                                 0)]

def_agrupada[, prop_m := fifelse(sexo_conocido > 0,
                                 mujeres / sexo_conocido,
                                 0)]

def_agrupada[, hombres := hombres + prop_h * sexo_no_esp]
def_agrupada[, mujeres := mujeres + prop_m * sexo_no_esp]

def_agrupada[, c("sexo_conocido", "prop_h", "prop_m") := NULL]

# Formato largo

def_larga <- melt(
  def_agrupada,
  id.vars = c("anio_ocurrencia", "edad"),
  measure.vars = c("hombres", "mujeres"),
  variable.name = "sexo",
  value.name = "defunciones"
)

def_larga[, sexo := ifelse(sexo == "hombres", "Hombres", "Mujeres")]

# Años de referencia

def_larga[, anio := case_when(
  anio_ocurrencia %in% c(2009, 2010, 2011) ~ 2010,
  anio_ocurrencia %in% c(2018, 2019) ~ 2019,
  anio_ocurrencia %in% c(2020, 2021, 2022) ~ 2021,
  TRUE ~ NA_real_
)]

defunciones <- def_larga[
  !is.na(anio),
  .(
    defunciones = mean(defunciones, na.rm = TRUE)
  ),
  by = .(anio, sexo, edad)
]

setorder(defunciones, anio, sexo, edad)


