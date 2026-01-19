@echo off
chcp 65001 > nul
set LANG=en_US.UTF-8

echo === Sistema Insta Solutions ===
echo.
echo Criando banco de dados...
bundle exec rails db:create

echo.
echo Executando migrações...
bundle exec rails db:migrate

echo.
echo === Iniciando servidor Rails ===
echo Acesse: http://localhost:3000
echo Pressione Ctrl+C para parar
echo.

bundle exec rails server -p 3000
