FROM php:8.4-cli

RUN apt-get update && apt-get install -y \
  git curl unzip libzip-dev zip \
  libpq-dev \
  && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip \
  && rm -rf /var/lib/apt/lists/*

# Node per build Vite
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
COPY . .

RUN mkdir -p /var/www/storage/logs \
 && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
 && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Dipendenze PHP
RUN composer install --no-dev --optimize-autoloader

# Crea link storage pubblico
RUN php artisan storage:link || true

# Dipendenze e build frontend (crea public/build/manifest.json)
RUN npm install
RUN npm run build
RUN ls -la public || true
RUN ls -la public/build || true
RUN test -f public/build/manifest.json


# Cache (opzionale ma consigliato)
# RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

EXPOSE 10000

CMD sh -c "php artisan serve --host=0.0.0.0 --port=${PORT:-10000}"