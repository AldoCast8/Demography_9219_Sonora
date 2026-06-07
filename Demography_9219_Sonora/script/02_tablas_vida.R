# ============================================================
# 02_tablas_vida.R
# Proyecto Sonora: APV y tablas de vida abreviadas
# ============================================================

# Este script parte de los objetos creados en 01_preparacion_datos.R:
#   - poblacion
#   - defunciones

if (!exists("poblacion") || !exists("defunciones")) {
  source("script/01_preparacion_datos.R")
}


# 1. Cálculo de APV mediante crecimiento exponencial

a_decimal <- function(fecha) {
  fecha <- as.Date(fecha)
  y <- as.numeric(format(fecha, "%Y"))
  inicio <- as.Date(paste0(y, "-01-01"))
  fin <- as.Date(paste0(y + 1, "-01-01"))
  y + as.numeric(fecha - inicio) / as.numeric(fin - inicio)
}

estimar_exp <- function(p0, p1, fecha0, fecha1, fecha_objetivo) {
  
  t0 <- a_decimal(fecha0)
  t1 <- a_decimal(fecha1)
  
  r <- log(p1 / p0) / (t1 - t0)
  
  p0 * exp(r * (fecha_objetivo - t0))
}

# Pasar población a formato ancho
pob_base <- dcast(
  poblacion,
  sexo + edad ~ anio,
  value.var = "poblacion"
)

# Estimar población expuesta a mitad de año
pob_base[, apv_2010 := estimar_exp(
  p0 = `2010`,
  p1 = `2020`,
  fecha0 = "2010-03-15",
  fecha1 = "2020-03-15",
  fecha_objetivo = 2010.5
)]

pob_base[, apv_2019 := estimar_exp(
  p0 = `2010`,
  p1 = `2020`,
  fecha0 = "2010-03-15",
  fecha1 = "2020-03-15",
  fecha_objetivo = 2019.5
)]

pob_base[, apv_2021 := estimar_exp(
  p0 = `2010`,
  p1 = `2020`,
  fecha0 = "2010-03-15",
  fecha1 = "2020-03-15",
  fecha_objetivo = 2021.5
)]

# Dejar APV en formato largo
apv <- melt(
  pob_base,
  id.vars = c("sexo", "edad"),
  measure.vars = c("apv_2010", "apv_2019", "apv_2021"),
  variable.name = "anio",
  value.name = "apv"
)

apv[, anio := as.numeric(gsub("apv_", "", anio))]
apv <- apv[, .(anio, sexo, edad, apv)]
setorder(apv, anio, sexo, edad)


# 2. Base para tabla de vida

base_mortalidad <- merge(
  apv,
  defunciones,
  by = c("anio", "sexo", "edad"),
  all.x = TRUE
)

base_mortalidad[is.na(defunciones), defunciones := 0]

base_mortalidad[, nmx := defunciones / apv]

base_mortalidad <- base_mortalidad[
  apv > 0 & !is.na(nmx) & is.finite(nmx)
]

setorder(base_mortalidad, anio, sexo, edad)


# 3. Funciones de tabla de vida

calcular_n <- function(edades) {
  c(diff(edades), NA_real_)
}

calcular_nax <- function(edades, n, nmx, sexo) {
  
  nax <- rep(NA_real_, length(edades))
  
  # Para grupos cerrados de 5 años o más se usa n/2
  nax[!(edades %in% c(0, 1)) & !is.na(n)] <- n[!(edades %in% c(0, 1)) & !is.na(n)] / 2
  
  m0 <- nmx[edades == 0][1]
  
  # Edad 0 y grupo 1-4 con Coale-Demeny
  if (sexo == "Hombres") {
    
    nax[edades == 0] <- ifelse(
      m0 >= 0.107,
      0.330,
      0.045 + 2.684 * m0
    )
    
    nax[edades == 1] <- ifelse(
      m0 >= 0.107,
      1.352,
      1.651 - 2.816 * m0
    )
    
  } else {
    
    nax[edades == 0] <- ifelse(
      m0 >= 0.107,
      0.350,
      0.053 + 2.800 * m0
    )
    
    nax[edades == 1] <- ifelse(
      m0 >= 0.107,
      1.361,
      1.522 - 1.518 * m0
    )
  }
  
  # Grupo abierto
  nax[length(nax)] <- 1 / nmx[length(nmx)]
  
  return(nax)
}

armar_tabla <- function(datos_grupo, anio_actual, sexo_actual, radix = 100000) {
  
  datos_grupo <- copy(datos_grupo)
  setorder(datos_grupo, edad)
  
  x <- datos_grupo$edad
  n <- calcular_n(x)
  nmx <- datos_grupo$nmx
  
  nax <- calcular_nax(
    edades = x,
    n = n,
    nmx = nmx,
    sexo = sexo_actual
  )
  
  # Probabilidad de muerte
  nqx <- (n * nmx) / (1 + (n - nax) * nmx)
  nqx[length(nqx)] <- 1
  nqx <- pmin(pmax(nqx, 0), 1)
  
  # Probabilidad de sobrevivir
  npx <- 1 - nqx
  
  # Sobrevivientes
  lx <- rep(NA_real_, length(x))
  lx[1] <- radix
  
  for (i in 2:length(x)) {
    lx[i] <- lx[i - 1] * npx[i - 1]
  }
  
  # Defunciones de la cohorte
  ndx <- lx * nqx
  
  # Años persona vividos
  nLx <- rep(NA_real_, length(x))
  
  for (i in 1:(length(x) - 1)) {
    nLx[i] <- n[i] * lx[i + 1] + nax[i] * ndx[i]
  }
  
  # Grupo abierto
  nLx[length(x)] <- lx[length(x)] / nmx[length(nmx)]
  
  # Años persona por vivir
  Tx <- rev(cumsum(rev(nLx)))
  
  # Esperanza de vida
  ex <- Tx / lx
  
  data.table(
    anio = anio_actual,
    sexo = sexo_actual,
    x = x,
    n = n,
    nmx = nmx,
    nax = nax,
    nqx = nqx,
    npx = npx,
    lx = lx,
    ndx = ndx,
    nLx = nLx,
    Tx = Tx,
    ex = ex
  )
}


# 4. Construir las seis tablas de vida
tablas_lista <- base_mortalidad[
  ,
  .(
    tabla = list(
      armar_tabla(
        datos_grupo = .SD,
        anio_actual = anio[1],
        sexo_actual = sexo[1],
        radix = raiz_tabla
      )
    )
  ),
  by = .(anio, sexo)
]

tabla_vida <- rbindlist(tablas_lista$tabla)

setorder(tabla_vida, anio, sexo, x)


# 5. Resumen de esperanza de vida al nacer

esperanza_vida <- tabla_vida[
  x == 0,
  .(
    anio,
    sexo,
    e0 = ex
  )
]

