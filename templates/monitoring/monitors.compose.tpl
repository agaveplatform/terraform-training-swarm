version: '2.2'

networks:
  monitoring:
  logging:

services:

  logspout:
    image: bekt/logspout-logstash:latest
    privileged: True
    networks:
      - logging
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      ROUTE_URIS: logstash://logstash:5000
      DOCKER_LABELS: "true"
    labels:
      - traefik.enable=false
    cpus: 0.25
    mem_limit: 64M
    mem_reservation: 32M
    restart: on-failure

  logstash:
    image: basi/logstash:v0.8.0
    networks:
      - logging
    ports:
      - 5000:5000
    environment:
      DEBUG:                  "false"
      LOGSPOUT:               ignore
      ELASTICSEARCH_USER:     ${ELASTICSEARCH_USER}
      ELASTICSEARCH_PASSWORD: ${ELASTICSEARCH_PASSWORD}
      ELASTICSEARCH_SSL:      ""
      ELASTICSEARCH_ADDR:     ${MONITORING_HOST}
      ELASTICSEARCH_PORT:     9200
    labels:
      - traefik.enable=false
    cpus: 0.25
    mem_limit: 800M
    mem_reservation: 400M
    restart: on-failure

  cadvisor:
    image: google/cadvisor:v0.25.0
    privileged: True
    networks:
      - monitoring
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock,readonly
      - /:/rootfs
      - /var/run:/var/run
      - /sys:/sys
      - /var/lib/docker/:/var/lib/docker
    labels:
      - traefik.enable=false
    cpus: 0.10
    mem_limit: 128M
    mem_reservation: 64M
    restart: on-failure

  node-exporter:
    image: basi/node-exporter:v1.13.0
    privileged: True
    networks:
      - monitoring
    volumes:
      - /proc:/host/proc
      - /sys:/host/sys
      - /:/rootfs
      - /etc/hostname:/etc/host_hostname
    environment:
      HOST_HOSTNAME: /etc/host_hostname
    command: -collector.procfs "/host/proc" -collector.sysfs /host/sys -collector.textfile.directory /etc/node-exporter/ -collectors.enabled 'conntrack,diskstats,entropy,filefd,filesystem,loadavg,mdadm,meminfo,netdev,netstat,stat,textfile,time,vmstat,ipvs' # -collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)"
    labels:
      - traefik.enable=false
    cpus: 0.10
    mem_limit: 32M
    mem_reservation: 16M
    restart: on-failure


  docker-exporter:
    image: basi/socat:v0.1.0
    networks:
      - monitoring
    labels:
      - traefik.enable=false
    cpus: 0.05
    mem_limit: 6M
    mem_reservation: 4M
