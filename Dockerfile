# ----- DOCKERFILE BACKEND (LARAVEL) - PHIÊN BẢN CUỐI CÙNG -----

# Sử dụng image PHP chính thức có sẵn web server Apache.
FROM php:8.2-apache

# Đặt thư mục làm việc
WORKDIR /var/www/html

# Cài đặt các thư viện hệ thống và extensions PHP cho PostgreSQL.
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

# Cài đặt Composer toàn cục
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy toàn bộ mã nguồn vào image
COPY . .

# Cài đặt dependencies của Composer
RUN composer install --no-dev --optimize-autoloader

# Tối ưu hóa Laravel cho production
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# --- CẤU HÌNH APACHE (PHƯƠNG PHÁP MỚI, ĐẢM BẢO THÀNH CÔNG) ---
# 1. Bật module rewrite
RUN a2enmod rewrite

# 2. COPY file config mới của chúng ta (apache-vhost.conf), ghi đè lên file mặc định
# Dòng 42 (ĐÚNG):
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
# -----------------------------------------------------------------

# Cấp quyền ghi cho thư mục storage và cache
RUN chown -R www-data:www-data storage bootstrap/cache

# LỆNH KHỞI ĐỘNG: Sửa cổng trong file config mới và khởi động Apache
CMD /bin/sh -c "sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/sites-available/000-default.conf && apache2-foreground"