#!/bin/sh

mkdir ./backup >/dev/null 2>&1
TIMESTAMP=`date +%Y-%m-%d_%H-%M-%S`
sudo docker compose exec -T database pg_dump -U teslamate teslamate > ./backup/teslamate_db.$TIMESTAMP
pigz -9 ./backup/teslamate_db.$TIMESTAMP
