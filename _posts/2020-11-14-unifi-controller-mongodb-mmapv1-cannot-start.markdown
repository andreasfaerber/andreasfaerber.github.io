---
title: "Unifi controller, docker, migration to new host: Cannot start server with an unknown storage engine: mmapv1, terminating"
layout: single
classes: wide
date: 2020-11-14 14:13 +100
categories:
  - troubleshooting
  - unifi
  - unifi-controller
  - mongodb
  - docker
  - backup
  - restore
---
While upgrading to a new raspberry pi 4 B i also moved my dockerized unifi-controller to the new raspberry by simple rsync'ing the
data directory and the docker-compose file i was using. After starting it i wondered why it takes so long for it to come up - and it
never came up (nothing listening on the http port for the unifi-controller). Here's why (from the mongo db server log of the container, "/config/logs/mongod.log" where /config is the bind mounted directory for the docker container):

```
2020-11-14T13:13:31.390+0000 I CONTROL  [main] ***** SERVER RESTARTED *****
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] MongoDB starting : pid=632 port=27117 dbpath=/usr/lib/unifi/data/db 64-bit host=4d03c9548de2
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] db version v3.4.24
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] git version: 865b4f6a96d0f5425e39a18337105f33e8db504d
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] OpenSSL version: OpenSSL 1.0.2g  1 Mar 2016
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] allocator: tcmalloc
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] modules: none
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] build environment:
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten]     distmod: ubuntu1604
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten]     distarch: aarch64
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten]     target_arch: aarch64
2020-11-14T13:13:31.400+0000 I CONTROL  [initandlisten] options: { net: { bindIp: "127.0.0.1", port: 27117, unixDomainSocket: { pathPrefix: "/usr/lib/unifi/run" } }, storage: { dbPath: "/usr/lib/unifi/data/db" }, systemLog: { destination: "file", logAppend: true, path: "/usr/lib/unifi/logs/mongod.log" } }
2020-11-14T13:13:31.410+0000 I -        [initandlisten] Detected data files in /usr/lib/unifi/data/db created by the 'mmapv1' storage engine, so setting the active storage engine to 'mmapv1'.
2020-11-14T13:13:31.410+0000 I STORAGE  [initandlisten] exception in initAndListen: 18656 Cannot start server with an unknown storage engine: mmapv1, terminating
2020-11-14T13:13:31.410+0000 I NETWORK  [initandlisten] shutdown: going to close listening sockets...
2020-11-14T13:13:31.410+0000 I NETWORK  [initandlisten] removing socket file: /usr/lib/unifi/run/mongodb-27117.sock
2020-11-14T13:13:31.410+0000 I NETWORK  [initandlisten] shutdown: going to flush diaglog...
2020-11-14T13:13:31.410+0000 I CONTROL  [initandlisten] now exiting
2020-11-14T13:13:31.410+0000 I CONTROL  [initandlisten] shutting down with code:100
```

So the change of architecture (?) resulted in the mongodb not being able to read the data files from the older raspberry pi 3b. After giving
this some thought i came across [UniFi - How to Create and Restore a Backup](https://help.ui.com/hc/en-us/articles/204952144-UniFi-How-to-Create-and-Restore-a-Backup). The rest was easy: I ran the unifi-controller on the old raspberry pi 3b, created
a backup, stopped the container, removed all the data on the new raspberry, started a fresh unifi-controller and restored it from backup. Voila!
