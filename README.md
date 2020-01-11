Версия руби 2.6.5

Для запуска парсера лог файла необходимо в файле db/seeds.rb указать пути для лог файла, и для файла бд MaxMind Geo Lite Country (mmdb)

```
bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
```

Так же можно опустить этот момент, так как готовая база sqlite лежит в репозитории.

Для запуска сервера необходимо выполнить следующие команды в консоли:

```
cd log_analizer
bundle install

bundle exec rackup
```
Приложение станет доступно по ссылке:

http://localhost:9292
