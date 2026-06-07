# ============================================================
# 03_visualizacion.R
# Proyecto Sonora: gráficas y tablas visuales
# ============================================================

# Este script parte de los objetos creados en:
# 01_preparacion_datos.R y 02_tablas_vida.R

if (!exists("tabla_vida") || !exists("esperanza_vida")) {
  source("script/01_preparacion_datos.R")
  source("script/02_tablas_vida.R")
}

# Paquetes

paquetes_vis <- c("ggplot2", "data.table", "dplyr", "gt", "webshot2")

faltantes_vis <- paquetes_vis[!paquetes_vis %in% installed.packages()[, "Package"]]

if (length(faltantes_vis) > 0) {
  install.packages(faltantes_vis, dependencies = TRUE)
}

invisible(lapply(paquetes_vis, library, character.only = TRUE))

# Carpetas de salida

ruta_graficas <- file.path(ruta_output, "graficas")
ruta_tablas <- file.path(ruta_output, "tablas_vida")

if (!dir.exists(ruta_graficas)) {
  dir.create(ruta_graficas, recursive = TRUE)
}

if (!dir.exists(ruta_tablas)) {
  dir.create(ruta_tablas, recursive = TRUE)
}

# Preparar bases

tv_graf <- copy(tabla_vida)

tv_graf[, anio := factor(anio)]
tv_graf[, sexo := factor(sexo, levels = c("Hombres", "Mujeres"))]

ev_graf <- copy(esperanza_vida)

ev_graf[, anio := factor(anio)]
ev_graf[, sexo := factor(sexo, levels = c("Hombres", "Mujeres"))]

# Paletas de colores

colores_anio <- c(
  "2010" = "#386641",
  "2019" = "#BC6C25",
  "2021" = "#6A4C93"
)

colores_sexo <- c(
  "Hombres" = "#3A86FF",
  "Mujeres" = "#D63384"
)

# 1. Gráfica de tasas centrales de mortalidad nmx

g_nmx <- ggplot(
  tv_graf,
  aes(x = x, y = nmx, color = anio, group = anio)
) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 1.4) +
  facet_wrap(~ sexo) +
  scale_y_log10() +
  scale_color_manual(values = colores_anio) +
  labs(
    title = "Tasas centrales de mortalidad por edad",
    subtitle = "Sonora, 2010, 2019 y 2021",
    x = "Edad inicial del grupo",
    y = "nmx, escala logarítmica",
    color = "Año"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

ggsave(
  filename = file.path(ruta_graficas, "01_tasas_centrales_mortalidad.png"),
  plot = g_nmx,
  width = 9,
  height = 5.4,
  dpi = 300
)

# 2. Gráfica de probabilidades de muerte nqx

g_nqx <- ggplot(
  tv_graf,
  aes(x = x, y = nqx, color = anio, group = anio)
) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 1.4) +
  facet_wrap(~ sexo) +
  scale_y_log10() +
  scale_color_manual(values = colores_anio) +
  labs(
    title = "Probabilidades de muerte por edad",
    subtitle = "Sonora, 2010, 2019 y 2021",
    x = "Edad inicial del grupo",
    y = "nqx, escala logarítmica",
    color = "Año"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

ggsave(
  filename = file.path(ruta_graficas, "02_probabilidades_muerte.png"),
  plot = g_nqx,
  width = 9,
  height = 5.4,
  dpi = 300
)

# 3. Gráfica de sobrevivientes lx

g_lx <- ggplot(
  tv_graf,
  aes(x = x, y = lx, color = anio, group = anio)
) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~ sexo) +
  scale_color_manual(values = colores_anio) +
  labs(
    title = "Sobrevivientes de la cohorte hipotética",
    subtitle = "Raíz de la tabla: 100,000 nacimientos",
    x = "Edad inicial del grupo",
    y = "lx",
    color = "Año"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

ggsave(
  filename = file.path(ruta_graficas, "03_sobrevivientes_lx.png"),
  plot = g_lx,
  width = 9,
  height = 5.4,
  dpi = 300
)

# 4. Gráfica de defunciones de la cohorte ndx

g_ndx <- ggplot(
  tv_graf,
  aes(x = x, y = ndx, color = anio, group = anio)
) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 1.3) +
  facet_wrap(~ sexo) +
  scale_color_manual(values = colores_anio) +
  labs(
    title = "Defunciones de la cohorte hipotética",
    subtitle = "Distribución de ndx por edad, sexo y año",
    x = "Edad inicial del grupo",
    y = "ndx",
    color = "Año"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

ggsave(
  filename = file.path(ruta_graficas, "04_defunciones_cohorte_ndx.png"),
  plot = g_ndx,
  width = 9,
  height = 5.4,
  dpi = 300
)

# 5. Cambio acumulado en esperanza de vida al nacer

# Tomamos 2010 como año base.
# Así la gráfica se centra en cero y muestra incrementos o caídas
# respecto al inicio del periodo.

ev_base <- copy(esperanza_vida)

ev_base <- ev_base[
  ,
  e0_base := e0[anio == 2010],
  by = sexo
]

ev_base[, cambio_e0 := e0 - e0_base]

ev_base[, anio := factor(anio, levels = c(2010, 2019, 2021))]
ev_base[, sexo := factor(sexo, levels = c("Hombres", "Mujeres"))]

colores_sexo_cambio <- c(
  "Hombres" = "#3A86FF",
  "Mujeres" = "#D63384"
)

g_e0 <- ggplot(
  ev_base,
  aes(x = anio, y = cambio_e0, color = sexo, group = sexo)
) +
  geom_hline(yintercept = 0, linewidth = 0.5, linetype = "dashed", color = "gray40") +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  scale_color_manual(values = colores_sexo_cambio) +
  labs(
    title = "Cambio acumulado en la esperanza de vida al nacer",
    subtitle = "Sonora, cambio respecto a 2010",
    x = "Año",
    y = "Cambio en e0 respecto a 2010",
    color = "Sexo"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

ggsave(
  filename = file.path(ruta_graficas, "05_cambio_acumulado_esperanza_vida.png"),
  plot = g_e0,
  width = 8,
  height = 5,
  dpi = 300
)


# 6. Exportar tablas de vida visuales

crear_tabla_gt <- function(base, anio_sel, sexo_sel) {
  
  # Paletas distintas al proyecto anterior
  color_principal <- ifelse(
    sexo_sel == "Hombres",
    "#0B3954",   # azul petróleo
    "#8A1C4A"    # vino/rosa oscuro
  )
  
  color_suave <- ifelse(
    sexo_sel == "Hombres",
    "#E6F0F5",
    "#F7E7EF"
  )
  
  tabla_aux <- base[
    anio == anio_sel & sexo == sexo_sel,
    .(
      x = x,
      n = n,
      nmx = round(nmx, 7),
      nax = round(nax, 4),
      nqx = round(nqx, 7),
      npx = round(npx, 7),
      lx = round(lx, 0),
      ndx = round(ndx, 0),
      nLx = round(nLx, 0),
      Tx = round(Tx, 0),
      ex = round(ex, 2)
    )
  ]
  
  gt(tabla_aux) |>
    tab_header(
      title = paste0("Sonora - ", anio_sel, " | ", sexo_sel)
    ) |>
    cols_label(
      x = "x",
      n = "n",
      nmx = "nmx",
      nax = "nax",
      nqx = "nqx",
      npx = "npx",
      lx = "lx",
      ndx = "ndx",
      nLx = "nLx",
      Tx = "Tx",
      ex = "ex"
    ) |>
    fmt_number(
      columns = c(nmx, nqx, npx),
      decimals = 7
    ) |>
    fmt_number(
      columns = c(nax, ex),
      decimals = 2
    ) |>
    fmt_number(
      columns = c(lx, ndx, nLx, Tx),
      decimals = 0,
      use_seps = TRUE
    ) |>
    tab_style(
      style = list(
        cell_fill(color = color_principal),
        cell_text(color = "white", weight = "bold", size = px(22))
      ),
      locations = cells_title(groups = "title")
    ) |>
    tab_style(
      style = list(
        cell_fill(color = color_principal),
        cell_text(color = "white", weight = "bold")
      ),
      locations = cells_column_labels(everything())
    ) |>
    tab_style(
      style = list(
        cell_fill(color = color_suave),
        cell_text(color = color_principal, weight = "bold")
      ),
      locations = cells_column_spanners(everything())
    ) |>
    tab_style(
      style = cell_fill(color = "#F7F7F7"),
      locations = cells_body(
        rows = seq(2, nrow(tabla_aux), by = 2)
      )
    ) |>
    tab_style(
      style = list(
        cell_text(weight = "bold", color = color_principal)
      ),
      locations = cells_body(columns = c(x, n))
    ) |>
    tab_options(
      table.font.names = "Arial",
      table.font.size = px(10),
      table.background.color = "white",
      heading.background.color = color_principal,
      column_labels.background.color = color_principal,
      table.border.top.color = color_principal,
      table.border.top.width = px(4),
      table.border.bottom.color = color_principal,
      table.border.bottom.width = px(4),
      data_row.padding = px(3),
      column_labels.border.bottom.color = color_principal,
      row_group.border.top.color = color_principal
    )
}

# Guardar tablas visuales
for (a in anios_objetivo) {
  for (s in c("Hombres", "Mujeres")) {
    
    tabla_visual <- crear_tabla_gt(
      base = tabla_vida,
      anio_sel = a,
      sexo_sel = s
    )
    
    nombre_sexo <- ifelse(s == "Hombres", "hombres", "mujeres")
    
    gtsave(
      data = tabla_visual,
      filename = file.path(
        ruta_tablas,
        paste0("tabla_vida_sonora_", a, "_", nombre_sexo, ".png")
      )
    )
  }
}

# 7. Tabla visual de esperanza de vida

tabla_e0_wide <- dcast(
  esperanza_vida,
  sexo ~ anio,
  value.var = "e0"
)

tabla_e0_wide[, `2010` := round(`2010`, 2)]
tabla_e0_wide[, `2019` := round(`2019`, 2)]
tabla_e0_wide[, `2021` := round(`2021`, 2)]
tabla_e0_wide[, `Cambio 2019-2021` := round(`2021` - `2019`, 2)]

tabla_e0_gt <- gt(tabla_e0_wide) |>
  tab_header(
    title = "Esperanza de vida al nacer",
    subtitle = "Sonora, 2010, 2019 y 2021"
  ) |>
  cols_label(
    sexo = "Sexo",
    `2010` = "2010",
    `2019` = "2019",
    `2021` = "2021",
    `Cambio 2019-2021` = "Cambio 2019-2021"
  ) |>
  fmt_number(
    columns = c(`2010`, `2019`, `2021`, `Cambio 2019-2021`),
    decimals = 2
  ) |>
  tab_style(
    style = list(
      cell_fill(color = "#F8F9FA"),
      cell_text(color = "#222222", weight = "bold", size = px(20))
    ),
    locations = cells_title(groups = "title")
  ) |>
  tab_style(
    style = list(
      cell_fill(color = "#F8F9FA"),
      cell_text(color = "#666666", size = px(13))
    ),
    locations = cells_title(groups = "subtitle")
  ) |>
  tab_style(
    style = list(
      cell_fill(color = "#324A5F"),
      cell_text(color = "white", weight = "bold")
    ),
    locations = cells_column_labels(everything())
  ) |>
  tab_style(
    style = list(
      cell_fill(color = "#EAF4FB"),
      cell_text(color = "#145DA0", weight = "bold")
    ),
    locations = cells_body(rows = sexo == "Hombres")
  ) |>
  tab_style(
    style = list(
      cell_fill(color = "#FBEAF2"),
      cell_text(color = "#A3165C", weight = "bold")
    ),
    locations = cells_body(rows = sexo == "Mujeres")
  ) |>
  tab_style(
    style = list(
      cell_text(weight = "bold")
    ),
    locations = cells_body(columns = `Cambio 2019-2021`)
  ) |>
  tab_options(
    table.font.names = "Arial",
    table.font.size = px(14),
    table.background.color = "white",
    heading.background.color = "#F8F9FA",
    table.border.top.color = "#324A5F",
    table.border.top.width = px(2),
    table.border.bottom.color = "#324A5F",
    table.border.bottom.width = px(2),
    column_labels.border.bottom.color = "#324A5F",
    column_labels.border.bottom.width = px(2),
    data_row.padding = px(7),
    table.width = pct(85)
  )

gtsave(
  data = tabla_e0_gt,
  filename = file.path(ruta_tablas, "resumen_esperanza_vida_sonora.png")
)

