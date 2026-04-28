# AVVIO PROGETTO DOCKER
```
cd database-docker-postgres
```
```
docker-compose up -d
```

## esportare i dati
```
docker exec pg-parcheggi pg_dump -U postgres parcheggi_uda > backup.sql
```

## importare i dati
```
docker exec -i pg-parcheggi psql -U postgres -d parcheggi_uda < backup.sql
```