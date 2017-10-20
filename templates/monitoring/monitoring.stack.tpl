version: '3.2'

networks:
  monitoring:
  application:
  logging:
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}

services:

  visualizer:
    image: dockersamples/visualizer:stable
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
      labels:
        - "environment=training"
        - "traefik.port=8080"
        - "traefik.tags=visualizer,monitoring"
        - "traefik.backend=visualizer"
        - "traefik.protocol=http"
        - "traefik.frontend.rule=Host:ops-viz.${WILDCARD_DOMAIN_NAME}"
        - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
    networks:
      - swarm_overlay

  portainer:
    image: ${PORTAINER_IMAGE}
    command: -H unix:///var/run/docker.sock
    deploy:
      labels:
        - "environment=training"
        - "traefik.port=9000"
        - "traefik.tags=portainer,monitoring"
        - "traefik.backend=portainer"
        - "traefik.protocol=http"
        - "traefik.frontend.rule=Host:ops-portainer.${WILDCARD_DOMAIN_NAME}"
        - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
      placement:
        constraints: [node.role == manager]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - swarm_overlay

  elasticsearch:
    image: bobbydvo/ukc_elasticsearch:latest
    ports:
      - "9200"
    networks:
      - logging
      - swarm_overlay
    deploy:
      labels:
        - traefik.enable=false
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure

  kibana:
    image: bobbydvo/ukc_kibana:latest
    ports:
      - "5601:5601"
    networks:
      - swarm_overlay
      - logging
    deploy:
      labels:
        - "environment=training"
        - "traefik.port=5601"
        - "traefik.tags=kibana,monitoring"
        - "traefik.backend=kibana"
        - "traefik.protocol=http"
        - "traefik.frontend.rule=Host:ops-kibana.${WILDCARD_DOMAIN_NAME}"
        - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure

  prometheus:
    image: ${PROMETHEUS_IMAGE}
    ports:
      - "9090"
    networks:
      - monitoring
      - swarm_overlay
    command: -config.file=/etc/prometheus/prometheus.yml -storage.local.path=/prometheus -web.console.libraries=/etc/prometheus/console_libraries -web.console.templates=/etc/prometheus/consoles -alertmanager.url=http://alertmanager:9093
    deploy:
      labels:
        - traefik.enable=false
      placement:
        constraints: [node.role == manager]
      mode: replicated
      replicas: 1
      resources:
        limits:
          cpus: "0.50"
          memory: 1024M
        reservations:
          cpus: "0.50"
          memory: 128M
      restart_policy:
        condition: on-failure

  grafana:
    image: ${GRAFANA_IMAGE}
    ports:
      - "3000:3000"
    networks:
      - monitoring
      - swarm_overlay
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
      PROMETHEUS_ENDPOINT: http://prometheus:9090
      ELASTICSEARCH_ENDPOINT: http://elasticsearch:9200
      ELASTICSEARCH_USER: ${ELASTICSEARCH_USER}
      ELASTICSEARCH_PASSWORD: ${ELASTICSEARCH_PASSWORD}
    deploy:
      labels:
        - "environment=training"
        - "traefik.port=3000"
        - "traefik.tags=grafana,monitoring"
        - "traefik.backend=grafana"
        - "traefik.protocol=http"
        - "traefik.frontend.rule=Host:ops-grafana.${WILDCARD_DOMAIN_NAME}"
        - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
      placement:
        constraints: [node.role == manager]
      mode: replicated
      replicas: 1
      resources:
        limits:
          cpus: "0.50"
          memory: 64M
        reservations:
          cpus: "0.50"
          memory: 32M
      restart_policy:
        condition: on-failure

  alertmanager:
    image: ${ALERTMANAGER_IMAGE}
    networks:
      - monitoring
      - swarm_overlay
    ports:
     - "9093:9093"
    environment:
      SLACK_API: ${SLACK_TOKEN}
      LOGSTASH_URL: http://logstash:8080/
    command: -config.file=/etc/alertmanager/config.yml
    deploy:
      labels:
        - traefik.enable=false
      placement:
        constraints: [node.role == manager]
      mode: replicated
      replicas: 1
      resources:
        limits:
          cpus: "0.01"
          memory: 32M
        reservations:
          cpus: "0.01"
          memory: 16M
      restart_policy:
        condition: on-failure
