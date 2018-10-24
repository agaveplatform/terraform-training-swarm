# gitlab.rb

external_url 'http://gitlab.${${WILDCARD_DOMAIN_NAME}'
registry_external_url 'http://registry.${WILDCARD_DOMAIN_NAME}'

# Disable services
postgresql['enable'] = false
redis['enable'] = false
prometheus['enable'] = false
postgres_exporter['enable'] = false
redis_exporter['enable'] = false

# Postgres settings
gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"

# database service will be named "postgres" in the stack
gitlab_rails['db_host'] = "postgres"
gitlab_rails['db_database'] = "${GITLAB_DB_NAME}"
gitlab_rails['db_username'] = "${GITLAB_DB_USERNAME}"
gitlab_rails['db_password'] = "${GITLAB_DB_PASSWORD}"

# Redis settings
# redis service will be named "redis" in the stack
gitlab_rails['redis_host'] = "redis"

# Prometheus exporters
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_monitor['listen_address'] = '0.0.0.0'
gitaly['prometheus_listen_addr'] = "0.0.0.0:9236"
gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"