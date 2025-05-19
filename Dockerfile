# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS flutterbuilder
WORKDIR /app

# Copy pubspec → tận dụng cache
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy toàn bộ source và build web
COPY . .
RUN flutter build web --release

# Stage 2: Serve với nginx
FROM nginx:1.25.3-alpine
COPY --from=flutterbuilder /app/build/web /usr/share/nginx/html
EXPOSE 80
