FROM ubuntu
MAINTAINER fgg.tut@gmail.com

# Install cron and netstat
RUN apt-get update && apt-get install cron net-tools -y -qq

COPY portsagent.sh /opt/portsagent
RUN chmod +x /opt/portsagent

# Register cronjob to start the script and redirect its stdout/stderr
# to the stdout/stderr of the entry process by adding lines to /etc/crontab
RUN echo "*/1 * * * * root /opt/portsagent > /proc/1/fd/1 2>/proc/1/fd/2" >> /etc/crontab

# Start cron in foreground (don't fork)
ENTRYPOINT [ "cron", "-f" ]


