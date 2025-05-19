# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS flutterbuilder

WORKDIR /app

# Copy pubspec files first (tận dụng cache)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy toàn bộ source sau khi pub get xong
COPY . .

# Kiểm tra dependencies, tránh lỗi thiếu thư viện Material
RUN flutter doctor

# Build web release
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:1.25.3-alpine

# Copy build files to Nginx web root
COPY --from=flutterbuilder /app/build/web /usr/share/nginx/html

# Remove default Nginx config & add custom (optional)
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
