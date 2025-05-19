# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS flutterbuilder
WORKDIR /app

# Copy pubspec first for caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy entire source
COPY . .

# Debug check (optional)
RUN flutter doctor
RUN ls -la lib/

# Build for web
RUN flutter build web --release

# Stage 2: Serve via nginx
FROM nginx:1.25.3-alpine
COPY --from=flutterbuilder /app/build/web /usr/share/nginx/html
EXPOSE 80
