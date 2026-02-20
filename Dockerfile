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

# Dipendenze PHP
RUN composer install --no-dev --optimize-autoloader

# Dipendenze e build frontend (crea public/build/manifest.json)
RUN npm ci && npm run build

# Cache (opzionale ma consigliato)
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

EXPOSE 10000

CMD php artisan serve --host=0.0.0.0 --port=10000