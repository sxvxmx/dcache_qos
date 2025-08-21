# dcache_qos

## Описание ##
В данном проекте система хранения dcache версии 10.2 запускается с помощью docker-compose для локальной отладки сервиса qos. \
Основную информацию о сервисе можно найти: [dcache qos](https://dcache.org/manuals/Book-10.2/config-qos-engine.shtml).

## Быстрый старт ## 
Для того чтобы запустить и проверить работу системы потребуется [docker engine](https://docs.docker.com/engine/install/). Для запуска проекта потребуется время, так как сервисы блокируют базу данных. Последний сервис - pinmanager, выполняет ``` sleep 60 ```.\
Запуск производится командой в директории с compose.yaml:
```
docker compose up --build
```

После этого можно записать файлы с помощью webdav:
```
curl -u admin:qq -T testfile.txt http://localhost:2880/data/testfile.txt
```
И проверить расположение файла с помощью frontend:

```
curl -u admin:qq -X GET "http://localhost:3880/api/v1/namespace/data/testfile.txt?locations=true"
```
,если конфигурация не изменена то, get вернет: 
```json
{
  "fileMimeType" : "text/plain",
  "labels" : [ ],
  "locations" : [ "pool1", "pool2", "pool3" ],
  "fileType" : "REGULAR",
  "pnfsId" : "000039D721C9265B4F2AAE4D9DDDD118CA84",
  "nlink" : 1,
  "mtime" : 1755784330042,
  "mode" : 420,
  "size" : 20,
  "creationTime" : 1755784329577
}
```

## Описание проекта ##
Проект состоит из группы директорий dcache-* и представляет собой различные сервисы, запускаемые для обеспечения работы системы. Внутри каждой директории присутствует индивидуальный конфиг dcache-*/config/, где описаны файлы .conf и в особенности mylayout.conf для каждого сервиса. 

Также внутри каждой директории присутствует dockerfile для сбора каждого сервиса в независимый контейнер. Скрипт entrypoint.sh позволяет выполнить настройку среды во время запуска в контейнере, затем отслеживается log файл каждого сервиса. (/var/log/dcache/{DomainName}.log).
### Основные сервисы: ###
- dcache-core - основное ядро системы. Содержит [centralDomain/admin],
[centralDomain/pnfsmanager],
[centralDomain/cleaner-disk],
[centralDomain/poolmanager],
[centralDomain/billing],
[centralDomain/gplazma].\
А также базы данных __chimera__, __qos__, __pinmanager__.
- dcache-door - доступ к системе. Реализует [doorsDomain/webdav],
[frontendDomain/frontend].
- dcache-pinmanager - необходимый модуль для работы репликации [book](https://dcache.org/manuals/Book-10.2/config-pinmanager.shtml).
- dcache-pool - создание pool для записи файлов.
- dcache-qos - сервис QoS из компонент: [qosDomain/qos-engine],
[qosDomain/qos-verifier],
[qosDomain/qos-adjuster],
[qosDomain/qos-scanner].\
Также локальная база данных __qos__.

### Особенность конфигурации ### 
Для работы сервиса QoS требуется настройка poolmanager. Конфиг находится в dcache-core/config/poolmanager.conf. 
```
#QoS setup
psu create unit -store test:REPLICA@osm
psu set storage unit test:REPLICA@osm -required=3

psu create ugroup persistent-units
psu addto ugroup persistent-units test:REPLICA@osm

psu create pool pool1
psu create pool pool2
psu create pool pool3

psu create pgroup persistent-pools -primary
psu addto pgroup persistent-pools pool1
psu addto pgroup persistent-pools pool2
psu addto pgroup persistent-pools pool3

psu create link persistent-link any-protocol world-net persistent-units
psu set link persistent-link -readpref=10 -writepref=10 -cachepref=10
psu addto link persistent-link persistent-pools
```
Установка тегов для директорий, в которые записываются файлы производится скриптом dcache-core/chimera-init.sh:
```sh
chimera <<EOF
mkdir /data
writetag /data OSMTemplate "StoreName test"
writetag /data sGroup REPLICA
writetag /data AccessLatency ONLINE
chown 1000:1000 /data
exit
EOF
```
здесь представлен пример создания директории /data. Подробно про теги описано в [qos](https://dcache.org/manuals/Book-10.2/config-qos-engine.shtml) и [StorageClass](https://dcache.org/manuals/Book-10.2/config-PoolManager.shtml#:~:text=subgroup%20is%20updated.-,Storage%20Classes,-The%20storage%20class).

## Работа с frontend ##
При работе с frontend можно изменять режим qos для файла. Но для работы этой функции требуются правильно настроенные poolgroup. 
```
curl -u admin:qq -X GET "http://localhost:3880/api/v1/namespace/testfile.txt?qos=true"
```
позволяет получить политику [qosPolicy](https://dcache.org/manuals/Book-10.2/config-qos-engine.shtml#:~:text=service%20in%20QoS.-,CHANGING%20A%20FILE%E2%80%99S%20QOS,-This%20is%20currently).

Для изменения политики используется:
```
curl -v -u admin:qq -X POST -H "Content-Type: application/json" -d '{"action":"qos","target":"disk"}' http://localhost:3880/api/v1/namespace/data/testfile.txt
```

## Дальнейшая работа ##
1. Сейчас система работает с 3мя пулами, которые создаются в одном docker контейнере. Что не позволяет использовать -onlyOneCopyPer=hostname параметр. 
2. Чтобы была возможность менять режим qos, требуется создать различные группы пулов, с реализацией различных политик.