################################################################
# Global configuration
################################################################

# Duration to give active requests a chance to finish during hot-reloads.
# Can be provided in a format supported by Go's time.ParseDuration function or
# as raw values (digits). If no units are provided, the value is parsed assuming
# seconds.
#
# Optional
# Default: "10s"
#
# graceTimeOut = "10s"

# Enable debug mode
#
# Optional
# Default: false
#
debug = true

# Traefik logs file
# If not defined, logs to stdout
#
# Optional
#
#traefikLogsFile = "log/traefik.log"

# Access logs file
#
# Optional
#
#accessLogsFile = "log/access.log"

[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
      entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      CertFile = "/ssl/${WILDCARD_DOMAIN_NAME}.crt"
      KeyFile = "/ssl/${WILDCARD_DOMAIN_NAME}.key"

[web]
address = ":28443"

# Service listener
#
# Docker event listener. This will pick up container events from the
# Swarm masters listening to the local engine and assign frontend and backend
# names based on docker labels.
#
[docker]
swarmmode = true
watch = true
