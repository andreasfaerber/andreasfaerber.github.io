---
title: "Teslamate: Update der Teslamate Google Cloud Installation"
layout: single
classes: wide
date: 2023-10-09 22:37:22 +100
toc: true
categories:
  - tesla
  - teslamate
tags:
  - gcp
  - google cloud
  - step-by-step
---
Anbei eine weitere Schritt für Schritt Anleitung, um [Teslamate in der Google Cloud]({% post_url 2022-06-04-teslamate-google-cloud-kostenlos %}) zu aktualisieren. Allgemeine Voraussetzung: [Teslamate in der Google Cloud]({% post_url 2022-06-04-teslamate-google-cloud-kostenlos %}) installiert.

# Kurzübersicht #

Um die Version von Teslamate zu aktualisieren müssen wir in der docker-compose.yml Datei die Version eintragen, die gestartet werden soll. In der ursprünglichen Datei ist die Version 1.27.0 eingetragen. Hier aktualisieren wir auf 1.27.3. Hierzu melden wir uns an der virtuellen Maschine über die Console an, erstellen ein Backup der Datenbank, editieren die docker-compose.yml, downloaden die neue Version und starten Teslamate neu. Wie folgt:


# Anmelden auf der Console #

Wie in der Installations-Anleitung beschrieben auf der virtuellen Maschine anmelden:

![Konsolenfenster](/assets/images/2023-10-09-google-cloud-instanz-fenster.png)

# Backup erstellen #

Bevor wir aktualisieren erstellen wir ein Backup der Datenbank:

```bash
sudo docker-compose exec -T database pg_dump -U teslamate teslamate > ~/teslamate_db.2023-10-09
```

Damit erstellt ihr ein Backup, welches in eurem Home-Verzeichnis gespeichert wird:

```bash
andreas_faerber@docker-teslamate:~/docker-teslamate$ sudo docker-compose exec -T database pg_dump -U teslamate teslamate > ~/teslamate_db.2023-10-09
andreas_faerber@docker-teslamate:~/docker-teslamate$ ls -la ~/tesla*
-rw-r--r-- 1 andreas_faerber andreas_faerber 281208664 Oct  9 20:44 /home/andreas_faerber/teslamate_db.2023-10-09
andreas_faerber@docker-teslamate:~/docker-teslamate$ 
```

# Editieren der docker-compose.yml Datei #

Wir editieren jetzt die docker-compose.yml, so dass wir die Version von 1.27.0 auf 1.27.3 anpassen.

Das soll dann so aussehen (wir ändern VORHER in NACHHER):

VORHER:
```
services:
  teslamate:
    image: teslamate/teslamate:1.27.0
    restart: always

[...]
```

NACHHER:
```
services:
  teslamate:
    image: teslamate/teslamate:1.27.3
    restart: always

[...]
```

Dazu nutzen wir die folgenden Kommandos nach dem einloggen auf die virtuelle Maschine:

```bash
cd docker-teslamate
nano docker-compose.yml
```

Um die Datei zu speichern drückt ihr ^X (Control-x), beantwortet die Frage mit “y” (y drücken) und bei “File Name to Write: docker-compose.yml” drückt ihr einfach Return. Dann solltet ihr wieder auf dem Prompt in der Konsole sein:

```bash
andreas_faerber@docker-teslamate:~$ cd docker-teslamate/
andreas_faerber@docker-teslamate:~/docker-teslamate$ nano docker-compose.yml
andreas_faerber@docker-teslamate:~/docker-teslamate$ 
```

# Download des Updates #

Mit den folgenden Kommandos laden wir die neue Version von teslamate herunter:

```bash
sudo docker-compose pull
```

Ausgabe:

```bash
andreas_faerber@docker-teslamate:~/docker-teslamate$ sudo docker-compose pull
Pulling grafana   ... done
Pulling database  ... done
Pulling teslamate ... done
Pulling mosquitto ... done
Pulling proxy     ... done
andreas_faerber@docker-teslamate:~/docker-teslamate$ 
```

# Neustart von teslamate #

```bash
sudo docker-compose down
sudo docker-compose up -d
```

Ausgabe:

```bash
andreas_faerber@docker-teslamate:~/docker-teslamate$ sudo docker-compose down
Stopping docker-teslamate_grafana_1   ... done
Stopping docker-teslamate_proxy_1     ... done
Stopping docker-teslamate_database_1  ... done
Stopping docker-teslamate_teslamate_1 ... done
Stopping docker-teslamate_mosquitto_1 ... done
Removing docker-teslamate_grafana_1   ... done
Removing docker-teslamate_proxy_1     ... done
Removing docker-teslamate_database_1  ... done
Removing docker-teslamate_teslamate_1 ... done
Removing docker-teslamate_mosquitto_1 ... done
Removing network docker-teslamate_default
andreas_faerber@docker-teslamate:~/docker-teslamate$ sudo docker-compose up -d
Creating network "docker-teslamate_default" with the default driver
Creating docker-teslamate_teslamate_1 ... done
Creating docker-teslamate_mosquitto_1 ... done
Creating docker-teslamate_grafana_1   ... done
Creating docker-teslamate_proxy_1     ... done
Creating docker-teslamate_database_1  ... done
andreas_faerber@docker-teslamate:~/docker-teslamate$ 
```

# Fertig #

Voila!

