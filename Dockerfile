# ----- DOCKERFILE BACKEND (LARAVEL) - PHIÊN BẢN CUỐI CÙNG (SỬA LỖI CỔNG KÉP) -----

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

# --- CẤU HÌNH APACHE (SỬA LỖI 403 BẰNG CÁCH SỬA FILE MẶC ĐỊNH) ---

# 1. Trỏ DocumentRoot vào /public
RUN sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# 2. Bật AllowOverride All (để .htaccess hoạt động)
RUN sed -ri -e '/<Directory \/var\/www\/html>/, /<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# 3. Bật mod_rewrite
RUN a2enmod rewrite
# --- KẾT THÚC CẤU HÌNH APACHE ---

# Cấp quyền
RUN chown -R www-data:www-data storage bootstrap/cache

# LỆNH KHỞI ĐỘNG (SỬA LỖI CỔNG KÉP)
# Chỉ sửa file ports.conf. Đây là file chịu trách nhiệm chính cho việc Listen.
# Apache sẽ chỉ lắng nghe trên cổng $PORT mà Render cung cấp.
CMD /bin/sh -c "sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf && apache2-foreground"