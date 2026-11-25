# HW4: Django, PostgreSQL and Nginx

[GoIT assignment](https://www.edu.goit.global/uk/learn/28179789/32217374/35554195/homework)

This project runs a small Django application in Docker. The home page reads the current database name from PostgreSQL and returns it as JSON.

## How it works

1. Nginx receives a request on port 80.
2. Nginx sends the request to `django:8000`.
3. `django` is a network alias for the Compose service `web`.
4. Django runs a SQL query in the `db` service.
5. Django returns JSON through Nginx to the browser.

| Service | Purpose |
| --- | --- |
| `web` | Python 3.12, Django 6.1.3 and Gunicorn 27.0.1 |
| `db` | PostgreSQL 17 with data in the `postgres_data` volume |
| `nginx` | Reverse proxy on `127.0.0.1:80` |

Only Nginx has a published host port. The other services use the internal Docker network. Health checks make `web` wait for PostgreSQL and Nginx wait for `web`.

## Start

Use Linux with Docker Engine and the Docker Compose plugin. Run these commands from the project folder:

```bash
cp .env.example .env
```

Edit `.env`. Replace `POSTGRES_PASSWORD` and `DJANGO_SECRET_KEY` with your own random local values. Keep this file private. Git and the Docker build exclude it.

```bash
docker compose config --quiet
docker compose up -d --build --wait
docker compose ps
```

If your Linux user needs root access for Docker, add `sudo` before each `docker` command. This project uses the current `docker compose` command. The LMS examples use the older `docker-compose` spelling.

On startup, `web` applies Django migrations and then starts Gunicorn. Open [http://localhost](http://localhost) on the Docker host. The default response is:

```json
{"message": "Django is running behind Nginx.", "database": "course_db"}
```

The database name comes from a real SQL query, not a fixed response value.

## Mac with the Lima VM

Docker was tested inside the Ubuntu VM named `devops-hw3`. Port 80 belongs to that VM. From the Mac, open a local SSH tunnel:

```bash
ssh -F "$HOME/.lima/devops-hw3/ssh.config" \
  -o ExitOnForwardFailure=yes -N \
  -L 127.0.0.1:8080:127.0.0.1:80 lima-devops-hw3
```

Keep that terminal open and visit [http://localhost:8080](http://localhost:8080) on the Mac. Press Ctrl+C in the tunnel terminal to close it. Port 80 remains the entry point inside Ubuntu.

## Checks

```bash
docker compose exec -T web python manage.py check
docker compose exec -T web python manage.py test core -v 2
docker compose exec -T nginx nginx -t
curl --fail http://localhost/
```

The two tests check the PostgreSQL backend and the database query through the home page. Django creates a separate test database and removes it after the run.

Verified on 25 November 2026 in Ubuntu 24.04.4 LTS ARM64, with Docker 29.10.1 and Compose 5.8.0:

| Check | Result |
| --- | --- |
| Compose configuration and image build | Passed |
| `web`, `db` and `nginx` health checks | All healthy |
| Django tests against PostgreSQL | 2 passed |
| Django system check and migrations | No issues; migrations applied |
| Nginx configuration | Valid |
| HTTP in Ubuntu and through the Mac tunnel | 200 with `course_db` in JSON |
| Database container recreation | A test record remained in the named volume; HTTP still worked |

The running image used Python 3.12.16, Django 6.1.3, Gunicorn 27.0.1, PostgreSQL 17.12 and Nginx 1.30.8. Image tags may receive later patch updates.

## Stop

```bash
docker compose down
```

This stops this project and keeps the database volume. Adding `--volumes` would delete its data.

This is a local course lab. It has no HTTPS or public deployment.

## References

- [Compose networking and aliases](https://docs.docker.com/compose/how-tos/networking/)
- [Compose startup order and health checks](https://docs.docker.com/compose/how-tos/startup-order/)
- [Django PostgreSQL support](https://docs.djangoproject.com/en/6.1/ref/databases/#postgresql-notes)
- [Nginx proxy_pass](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass)
