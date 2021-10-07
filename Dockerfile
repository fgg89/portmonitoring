FROM centos:latest
MAINTAINER fgg.tut@gmail.com

# Install netstat
RUN yum update -y && yum install -y git vim net-tools && yum clean all

RUN touch /var/log/portsagent.log
COPY portsagent.sh /opt/portsagent
RUN chmod +x /opt/portsagent

ENTRYPOINT [ "/opt/portsagent"]


