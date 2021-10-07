## Localhost testing

docker build -t cron .
docker run --net=host --name=cron -d cron
docker exec CONTAINER_ID tail -f /var/log/portsagent.log
