source("validation/R/normalizar-registros.R")
stopifnot(id_canonico("10.1000/ABC", "repo-1", "Título", "Núñez", 2020) ==
          "doi:10.1000/abc")
stopifnot(id_canonico(" doi:10.1000/ABC ", "repo-1", "Título", "Núñez", 2020) ==
          "doi:10.1000/abc")
stopifnot(id_canonico(" HTTPS://DX.DOI.ORG/10.1000/ABC ", "repo-1",
                     "Título", "Núñez", 2020) == "doi:10.1000/abc")
stopifnot(id_canonico("", "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(id_canonico(NA_character_, "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(id_canonico("NA", "repo-1", "Título", "Núñez", 2020) ==
          "repo:repo-1")
stopifnot(id_canonico("no_identificado", " doi:10.7910/DVN/AFJTQA ",
                     "Título", "Núñez", 2020) ==
          "repo:10.7910/dvn/afjtqa")
stopifnot(id_canonico("no_identificado",
                     " https://doi.org/10.7910/DVN/AFJTQA ",
                     "Título", "Núñez", 2020) ==
          "repo:10.7910/dvn/afjtqa")

meta_titulo <- id_canonico("no_identificado", "no_identificado",
                           " Título! ", " Núñez ", 2020)
meta_equivalente <- id_canonico("", "", "Titulo", "Nunez", 2020)
meta_distinto <- id_canonico("", "", "Otro título", "Nunez", 2020)
stopifnot(startsWith(meta_titulo, "meta:"))
stopifnot(identical(meta_titulo, meta_equivalente))
stopifnot(!identical(meta_titulo, meta_distinto))

leer <- function(nombre) utils::read.csv(nombre, check.names = FALSE,
                                         stringsAsFactors = FALSE)
busquedas <- leer("docs/validacion/registro-busqueda.csv")
cribado <- leer("docs/validacion/cribado-estudios.csv")

r1 <- subset(busquedas, ronda == 1)
stopifnot(all(c("Zenodo API", "Harvard Dataverse API", "OSF API nodes",
                "DataCite API", "Figshare API", "Dataverse global",
                "GESIS", "UK Data Service", "ICPSR") %in% r1$fuente))
stopifnot(all(r1$resultados_revisados >= 0L))
stopifnot(all(r1$enumeracion_completa %in% c("si", "no", "no_aplica")))
stopifnot(sum(cribado$ronda == 1L) == sum(r1$resultados_revisados))
