# ----- DOCKERFILE BACKEND (LARAVEL) - PHIÊN BẢN CUỐI CÙNG -----

# Sử dụng image PHP chính thức có sẵn web server Apache.
FROM php:8.2-apache
WORKDIR /var/www/html

# Cài đặt các thư viện hệ thống
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    git \
    libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo pdo_pgsql mbstring exif pcntl bcmath gd zip

# Cài đặt Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy code (dùng .dockerignore)
COPY . .

# Cài đặt dependencies
RUN composer install --no-dev --optimize-autoloader

# Tối ưu hóa Laravel
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# --- CẤU HÌNH APACHE (SỬA LỖI 403 & 404) ---
RUN a2enmod rewrite
# Copy file config mới (apache.conf) mà bạn vừa tạo
COPY apache.conf /etc/apache2/sites-available/000-default.conf
# ---------------------------------------------

# Cấp quyền
RUN chown -R www-data:www-data storage bootstrap/cache

# LỆNH KHỞI ĐỘNG (SỬA LỖI CỔNG KÉP CỦA RENDER)
# Sửa cổng trong file ports.conf VÀ file vhost 000-default.conf
# CMD /bin/sh -c "sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf && sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:${PORT}>/g' /etc/apache2/sites-available/000-default.conf && apache2-foreground"

RUN chown -R www-data:www-data storage bootstrap/cache

# LỆNH CMD DUY NHẤT (ĐÃ XUỐNG DÒNG CHO DỄ NHÌN)
CMD /bin/sh -c "php artisan migrate:fresh --force && \
    sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:${PORT}>/g' /etc/apache2/sites-available/000-default.conf && \
    apache2-foreground"