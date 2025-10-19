# ----- DOCKERFILE BACKEND (LARAVEL) - PHIÊN BẢN GITHUB -----
FROM php:8.2-apache
WORKDIR /var/www/html

# Cài đặt thư viện hệ thống
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

# --- CẤU HÌNH APACHE ---
RUN a2enmod rewrite
# COPY file config mới, đảm bảo tên file chính xác
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
# -------------------------

# Cấp quyền
RUN chown -R www-data:www-data storage bootstrap/cache

# LỆNH KHỞI ĐỘNG
CMD /bin/sh -c "sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/sites-available/000-default.conf && apache2-foreground"