---
title: "Pixelfed (v0.11.2) Docker Installation"
layout: single
classes: wide
date: 2022-05-01 19:32 +100
toc: true
categories:
  - pixelfed
  - fediverse
tags:
  - pixelfed
  - fediverse
  - docker
  - step-by-step
---
Step by step installation of pixelfed on docker - assuming you have docker
and git already installed. For testing purposes i will use pixeltest.maeh.org
as the domain name for the installation. Core setup based on [Pixelfed generic installation guide](https://docs.pixelfed.org/running-pixelfed/installation.html) and
[Pixelfed (beta) with Docker and Traefik](https://jonnev.se/pixelfed-beta-with-docker-and-traefik/)
from [Jon Neverland](https://jonnev.se/about/). Here we go:

# Clone repository #

```terminal

root@d02:~/docker# git clone https://github.com/pixelfed/pixelfed.git docker-maeh-pixeltest
Cloning into 'docker-maeh-pixeltest'...
remote: Enumerating objects: 44651, done.
remote: Counting objects: 100% (71/71), done.
remote: Compressing objects: 100% (55/55), done.
remote: Total 44651 (delta 24), reused 37 (delta 16), pack-reused 44580
Receiving objects: 100% (44651/44651), 40.96 MiB | 10.79 MiB/s, done.
Resolving deltas: 100% (28306/28306), done.
root@d02:~/docker# cd docker-maeh-pixeltest
root@d02:~/docker# 

```

# Amend .env.docker #

Amend at least the following variables in .env.docker:

```terminal
APP_URL=pixeltest.maeh.org
APP_DOMAIN=pixeltest.maeh.org
ADMIN_DOMAIN=pixeltest.maeh.org
SESSION_DOMAIN=pixeltest.maeh.org
```

# Amend docker-compose.yml #

I like to store persistent data in local directories on the docker host, so
i change the volume section as follows:

```terminal
volumes:
  db-data:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/tmp/docker-maeh-pixeltest/db-data'
  redis-data:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/tmp/docker-maeh-pixeltest/redis-data'
  app-storage:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/tmp/docker-maeh-pixeltest/app-storage'
  app-bootstrap:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/tmp/docker-maeh-pixeltest/app-bootstrap'
```
# Build the docker images #

Now build the docker images:

```terminal
docker-compose build
```

May take a moment.

# Create volume directories #

This creates all directories from the docker-compose.yml file.

```terminal
root@d02:~/docker/docker-maeh-pixeltest# grep tmp docker-compose.yml | awk '{print "mkdir -p "$2}' | sh
root@d02:~/docker/docker-maeh-pixeltest#
```

# Generate APP_KEY #

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose up -d
Creating network "docker-maeh-pixeltest_internal" with the default driver
Creating network "docker-maeh-pixeltest_external" with driver "bridge"
Creating volume "docker-maeh-pixeltest_db-data" with local driver
Creating volume "docker-maeh-pixeltest_redis-data" with local driver
Creating volume "docker-maeh-pixeltest_app-storage" with local driver
Creating volume "docker-maeh-pixeltest_app-bootstrap" with local driver
[.. it may take some time to pull the other containers ..]
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan key:generate
Application key set successfully.
root@d02:~/docker/docker-maeh-pixeltest# grep APP_KEY .env.docker
APP_KEY=base64:some-random-looking-string
root@d02:~/docker/docker-maeh-pixeltest#
```

# Restart container #

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose down && docker-compose up -d
Stopping docker-maeh-pixeltest_app_1    ... done
Stopping docker-maeh-pixeltest_worker_1 ... done
Stopping docker-maeh-pixeltest_redis_1  ... done
Stopping docker-maeh-pixeltest_db_1     ... done
Removing docker-maeh-pixeltest_app_1    ... done
Removing docker-maeh-pixeltest_worker_1 ... done
Removing docker-maeh-pixeltest_redis_1  ... done
Removing docker-maeh-pixeltest_db_1     ... done
Removing network docker-maeh-pixeltest_internal
Removing network docker-maeh-pixeltest_external
Creating network "docker-maeh-pixeltest_internal" with the default driver
Creating network "docker-maeh-pixeltest_external" with driver "bridge"
Creating docker-maeh-pixeltest_redis_1 ... done
Creating docker-maeh-pixeltest_db_1    ... done
Creating docker-maeh-pixeltest_worker_1 ... done
Creating docker-maeh-pixeltest_app_1    ... done
root@d02:~/docker/docker-maeh-pixeltest#
```

# Clear cache and run migrations #

Answer yes to the migration question.

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan config:cache
Configuration cache cleared!
Configuration cached successfully!
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan migrate
[.. clipped ..]
```

# Create your user #

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan user:create
Creating a new user...

 Name:
 > Test User

 Username:
 > testuser

 Email:
 > testuser@no.mail

 Password:
 >

 Confirm Password:
 >

 Make this user an admin? (yes/no) [no]:
 > yes

 Manually verify email address? (yes/no) [no]:
 > no

 Are you sure you want to create this user? (yes/no) [no]:
 > yes

Created new user!
root@d02:~/docker/docker-maeh-pixeltest# 
```

# Enable federation, oauth #

Set the following variables (example) in .env.docker:

```terminal
ACTIVITY_PUB=true
AP_REMOTE_FOLLOW=true
AP_SHAREDINBOX=true
AP_INBOX=true
AP_OUTBOX=true
```

(Each time) after changing the .env.docker file, run

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan config:cache
Configuration cache cleared!
Configuration cached successfully!
root@d02:~/docker/docker-maeh-pixeltest#
```

Run

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan instance:actor
Instance actor succesfully generated. You do not need to run this command again.
root@d02:~/docker/docker-maeh-pixeltest# 
```

Unless you disabled oauth, run:

```terminal
root@d02:~/docker/docker-maeh-pixeltest# docker-compose exec app php artisan passport:install
Encryption keys generated successfully.
Personal access client created successfully.
Client ID: 1
Client secret: some-random-string
Password grant client created successfully.
Client ID: 2
Client secret: some-other-random-string
root@d02:~/docker/docker-maeh-pixeltest#
```

Restart everything with ```docker-compose down && docker-compose up -d```.

# Voila #

Running behind my reverse proxy:

![Running pixelfed](/assets/images/2022-05-01-pixelfed-screenshot.png)
