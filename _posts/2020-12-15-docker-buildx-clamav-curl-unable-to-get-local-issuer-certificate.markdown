---
title: "Docker, buildx, arm, curl: (60) SSL certificate problem: unable to get local issuer certificate"
layout: single
classes: wide
date: 2020-12-15 20:39 +100
categories:
  - troubleshooting
  - docker
  - buildx
  - arm
  - curl
  - certificates
  - update-ca-certificates
---
While trying to build a docker mailserver for the arm platform for a small home mailserver i ran into an issue where i was not able
to properly build the arm images via a standard buildx pipeline. The job failed to fetch the clamav database for the arm platforms with

```
#8 [ 4/44] RUN curl -o /var/lib/clamav/daily.cvd https://database.clamav.ne...
#8 1.675   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#8 1.679                                  Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
#8 2.008 curl: (60) SSL certificate problem: unable to get local issuer certificate
#8 2.008 More details here: https://curl.haxx.se/docs/sslcerts.html
#8 2.008 
#8 2.008 curl failed to verify the legitimacy of the server and therefore could not
#8 2.008 establish a secure connection to it. To learn more about this situation and
#8 2.008 how to fix it, please visit the web page mentioned above.
```

Even though update-ca-certificates was run before the try to get the database i was not able to easily identify the issue. Well, in case
someone else wonders what the issue is and how to fix: Running **c_rehash** before running the specific command solved the issue.
