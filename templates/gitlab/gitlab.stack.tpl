# stack.yaml

version: "3.4"

services:
  gitlab:
    image: "${TRAINING_GITLAB_IMAGE}"
    volumes:
      - "gitlab_data:/var/opt/gitlab"
      - "gitlab_logs:/var/log/gitlab"
      - "gitlab_config:/etc/gitlab"
    ports:
      - "2222:22"
    configs:
      - source: "gitlab.rb"
        target: "/etc/gitlab/gitlab.rb"
    networks:
      - default
      - proxy
    deploy:
      placement:
        constraints: [node.label.slave == yes]
      labels:
        traefik.port: "80"
        traefik.frontend.rule: "Host:gitlab.${WILDCARD_DOMAIN_NAME}"
        traefik.protocol: "http"
        traefik.tags: "gitlab"
        traefik.backend: gitlab
        traefik.docker.network: ${SWARM_OVERLAY_NETWORK_NAME}"

  redis:
    image: "redis:4.0.6-alpine"
    deploy:
      placement:
        constraints: [node.label.slave == yes]

  postgres:
    image: "postgres:10.1-alpine"
    volumes:
      - "postgres_data:/data"
    environment:
      POSTGRES_USER: "${GITLAB_DB_USERNAME}"
      POSTGRES_PASSWORD: "${GITLAB_DB_PASSWORD}"
      PGDATA: "/data"
      POSTGRES_DB: "${GITLAB_DB_NAME}"
    deploy:
      placement:
        constraints: [node.label.slave == yes]

  prometheus:
    image: "prom/prometheus:v2.0.0"
    command: "--config.file=/prometheus.yaml --storage.tsdb.path /data"
    volumes:
      - "prometheus_data:/data"
    configs:
      - prometheus.yaml
    networks:
      - default
      - proxy
    deploy:
      placement:
        constraints: [node.label.slave == yes]
      labels:
        traefik.port: 9090
        traefik.frontend.rule: "Host:prometheus.${WILDCARD_DOMAIN_NAME}"
        traefik.docker.network: "${SWARM_OVERLAY_NETWORK_NAME}"

  grafana:
    image: grafana/grafana:4.6.3
    environment:
      GF_PATHS_CONFIG: "/grafana.ini"
    configs:
      - grafana.ini
    volumes:
      - "grafana_data:/data"
    networks:
      - default
      - proxy
    deploy:
      placement:
        constraints: [node.label.slave == yes]
      labels:
        traefik.port: 3000
        traefik.frontend.rule: "Host:grafana.${WILDCARD_DOMAIN_NAME}"
        traefik.docker.network: "${SWARM_OVERLAY_NETWORK_NAME}"

volumes:
  gitlab_data:
    driver: local
    driver_opts:
      type: nfs4
      o: "addr=127.0.0.1"
      device: ":/gitlab-swarm/gitlab/data"
  gitlab_logs:
    driver: local
    driver_opts:
      type: nfs4
      o: "addr=127.0.0.1"
      device: ":/gitlab-swarm/gitlab/logs"
  gitlab_config:
    driver: local
    driver_opts:
      type: nfs4
      o: "addr=127.0.0.1"
      device: ":/gitlab-swarm/gitlab/config"
  postgres_data:
    driver: local
    driver_opts:
      type: nfs4
      o: "addr=127.0.0.1"
      device: ":/gitlab-swarm/postgres"
  prometheus_data:
    driver: local
    driver_opts:
      type: nfs4
      o: "addr=127.0.0.1"
      device: ":/gitlab-swarm/prometheus"
  grafana_data:
    driver: local
    driver_opts:
      type: nfs4
      o: "addr=127.0.0.1"
      device: ":/gitlab-swarm/grafana"

configs:
  gitlab.rb:
    file: "./gitlab.rb"
  prometheus.yaml:
    file: "./prometheus.yaml"
  grafana.ini:
    file: "./grafana.ini"

networks:
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}