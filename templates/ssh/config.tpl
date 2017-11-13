Host github.com
  HostName                github.com
  IdentityFile            /run/secrets/deployment_private_key
  UserKnownHostsFile      /dev/null
  StrictHostKeyChecking   false

Host jenkins
  HostName                ${TRAINING_JENKINS_HOST}
  IdentityFile            /run/secrets/sandbox_private_key
  UserKnownHostsFile      /dev/null
  StrictHostKeyChecking   false

Host sandbox
  HostName                ${TRAINING_SANDBOX_HOST}
	Port 			              ${TRAINING_SANDBOX_PORT}
  IdentityFile            /run/secrets/sandbox_private_key
  UserKnownHostsFile      /dev/null
  StrictHostKeyChecking   false


Host *
UserKnownHostsFile
StrictHostKeyChecking
