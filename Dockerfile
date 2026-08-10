# Dockerfile para Flutter Web - UberMotor
# Optimizado para Railway deployment (mismo patron que Comanda)
# API_BASE_URL: build arg con la URL publica del backend (ej. https://xxx.up.railway.app)

FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

ARG API_BASE_URL=http://localhost:8000

WORKDIR /app

# Copiar archivos de configuracion primero (layer caching)
COPY pubspec.yaml ./

RUN flutter pub get

COPY . .

RUN flutter build web --release --base-href / --dart-define=API_BASE_URL=$API_BASE_URL

# Etapa de produccion - servidor HTTP ligero
FROM python:3.11-alpine AS runtime

RUN addgroup -g 1000 flutteruser && \
    adduser -u 1000 -G flutteruser -s /bin/sh -D flutteruser

RUN mkdir -p /app/web && chown -R flutteruser:flutteruser /app

USER flutteruser

COPY --from=build --chown=flutteruser:flutteruser /app/build/web /app/web

WORKDIR /app/web

EXPOSE 8080

CMD ["python", "-m", "http.server", "8080", "--bind", "0.0.0.0"]
