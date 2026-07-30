# Imagen del Calibrador fsQCA.
#
# rocker/r-ver clava la version de R y usa el repositorio binario de Posit
# para Ubuntu, asi que los paquetes NO se compilan desde fuente: la imagen
# se construye en minutos en vez de en una hora.
#
# La reproducibilidad la garantiza renv.lock, no la imagen: es el mismo
# archivo que reconstruye el entorno en la maquina de desarrollo.

FROM rocker/r-ver:4.6.1

# Dependencias de sistema de los paquetes que compilan algo (curl, xml2,
# fuentes para los graficos). Se instalan antes de renv para aprovechar
# la cache de capas.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libcurl4-openssl-dev \
      libssl-dev \
      libxml2-dev \
      libglpk-dev \
      libfontconfig1-dev \
      libfreetype6-dev \
      libpng-dev \
      libtiff5-dev \
      libjpeg-dev \
      pandoc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Primero solo el lockfile: si no cambia, Docker reutiliza la capa de
# paquetes y el despliegue tarda segundos.
COPY renv.lock renv.lock
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')" \
 && R -e "renv::restore(lockfile = 'renv.lock', prompt = FALSE)"

COPY pkg/ pkg/
COPY app/ app/
COPY informe/ informe/
COPY _quarto.yml _quarto.yml

# Fly enruta al puerto que declara fly.toml; la app tiene que escuchar en
# todas las interfaces, no solo en loopback.
ENV HOST_APP=0.0.0.0
ENV PUERTO=8080
EXPOSE 8080

# CLAVE_APP se inyecta como secreto de Fly, nunca se hornea en la imagen.
CMD ["Rscript", "app/app.R"]
