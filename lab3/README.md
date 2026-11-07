# Лабораторная работа 3: Ansible-деплой

## Состав стенда

`docker-compose.yml` запускает четыре контейнера в одной сети `labnet`:

- `ansible-master` — Ansible control node, с которого выполняется playbook;
- `nginx-target` — чистый Debian-контейнер, на который роль `nginx`
  устанавливает и настраивает Nginx;
- `app-target` — чистый Debian-контейнер, на который роль `app` устанавливает
  Python, распаковывает приложение и запускает его shell-скриптом;
- `postgres` — вспомогательный контейнер в общей сети.

В target-образе заранее установлены только SSH-сервер и сетевой инструмент,
необходимые для подключения Ansible. Python, Nginx и само приложение
устанавливаются playbook-ом.

## Структура Ansible

- `ansible/site.yml` — последовательность bootstrap, установки Nginx и
  деплоя приложения;
- `ansible/roles/nginx` — установка, конфигурация, проверка `nginx -t` и
  запуск Nginx;
- `ansible/roles/app` — установка Python, создание пользователя, распаковка
  релиза, установка environment-файла, проверка синтаксиса и запуск через
  `/opt/health-app/start.sh`;
- `ansible/inventory.ini` — адреса target-контейнеров внутри `labnet`.

## Сборка, запуск и проверка

Сборка и запуск стенда:

```bash
cd lab3
docker compose up -d --build
./wait-for-deployment.sh
```

`ansible-master` автоматически создаёт архив приложения и запускает
`ansible/site.yml`. После завершения деплоя master остаётся запущенным, чтобы
были доступны логи и результаты проверки.

Playbook явно использует `/workspace/ansible/ansible.cfg`, поэтому SSH-
подключение к ephemeral target-контейнерам не зависит от рабочего каталога
master-контейнера.

Скрипт `wait-for-deployment.sh` ожидает переход `ansible-master` в состояние
`healthy`. Это состояние устанавливается только после успешного завершения
playbook и создания marker-файла `/tmp/deployment-complete`.

Статус контейнеров:

```bash
docker compose ps
```

Проверка приложения через Nginx:

```bash
curl -i http://localhost:8080/health
```

Ожидается HTTP `200` и JSON `{"status": "UP"}`.

Логи Ansible и приложения:

```bash
docker compose logs ansible-master
docker compose exec app-target cat /var/log/health-app.log
```

Повторный запуск playbook:

```bash
docker compose exec ansible-master \
  ansible-playbook -i /workspace/ansible/inventory.ini /workspace/ansible/site.yml
```

Остановка стенда:

```bash
docker compose down
```

Для PR прикладываются скриншоты `docker compose ps`, успешного вывода
Ansible и `curl` с HTTP `200`.
