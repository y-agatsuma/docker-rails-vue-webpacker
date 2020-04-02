#!/bin/bash

echo "----- 1. docker pull ruby:2.7.0 -----"
docker pull ruby:2.7.0

echo "-----2. docker pull mysql:5.7 -----"
docker pull mysql:5.7
docker images

echo "----- 3. create Dockerfile -----"
APP_ROOT="/`pwd | xargs basename`"
cat <<EOF > Dockerfile
FROM ruby:2.7.0
ENV LANG C.UTF-8

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y build-essential \
    libpq-dev \
    nodejs \
    yarn \
    && rm -rf /var/lib/apt/lists/* \
    && yarn install --check-files

RUN mkdir $APP_ROOT
WORKDIR $APP_ROOT
ADD ./src/Gemfile $APP_ROOT/Gemfile
ADD ./src/Gemfile.lock $APP_ROOT/Gemfile.lock
RUN bundle install
ADD ./src/ $APP_ROOT
EOF

echo "----- 4. create Gemfile -----"
mkdir src && cd src
cat <<'EOF' > Gemfile
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.0'

gem 'rails', '~> 6.0.2', '>= 6.0.2.1'
gem 'mysql2', '>= 0.4.4', '< 0.6.0'
gem 'puma', '~> 4.1'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 4.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
EOF
touch Gemfile.lock
cd ../

echo "----- 5. create docker-compose.yml -----"
cat <<EOF > docker-compose.yml
version: '3'
services:
  db:
    image: mysql:5.7
    volumes:
      - ./src/db/mysql_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=password
    ports:
      - "3306:3306"
  web:
    build: .
    command: rails s -p 3000 -b '0.0.0.0'
    volumes:
      - ./src:$APP_ROOT
    environment:
      RAILS_ENV: development
      MYSQL_DATABASE: db_dev
      MYSQL_USERNAME: root
      MYSQL_PASSWORD: password
      MYSQL_HOST: db
    ports:
      - "3000:3000"
    links:
      - db
EOF

echo "----- 6. create Rails new app -----"
docker-compose build
docker-compose run web rails new . --force --database=mysql --webpack=vue --skip-bundle --skip-turbolinks

echo "----- 7. fix config/database.yml -----"
cd src
echo "fix config/database.yml"
cd config
rm database.yml
cat <<'EOF' > database.yml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  socket: /var/run/mysqld/mysqld.sock
  database: <%= ENV.fetch("MYSQL_DATABASE") %>
  username: <%= ENV.fetch("MYSQL_USERNAME") %>
  password: <%= ENV.fetch("MYSQL_PASSWORD") %>
  host: <%= ENV.fetch("MYSQL_HOST") %>
  
development:
  <<: *default

production:
  <<: *default
EOF
cd ../

echo "----- 8. create database -----"
docker-compose run web rake db:create

echo "----- 9. docker-compose up -d -----"
docker-compose up -d
