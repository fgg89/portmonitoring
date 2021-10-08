FROM centos:latest
MAINTAINER fgg.tut@gmail.com

# Install netstat
RUN yum update -y && yum install -y git vim net-tools && yum clean all
# Create folder and file for the app log
RUN mkdir /var/log/portscanner/
RUN touch /var/log/portscanner/portscanner.log
# Copy the script and assign execution permissions
COPY portscanner.sh /opt/portscanner
RUN chmod +x /opt/portscanner

ENTRYPOINT [ "/opt/portscanner"]


