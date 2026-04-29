#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

JENKINS_USER="${JENKINS_USER:-jenkins}"
JENKINS_GROUP="${JENKINS_GROUP:-jenkins}"
JENKINS_HOME_DIR="${JENKINS_HOME_DIR:-/home/${JENKINS_USER}}"
JENKINS_AGENT_DIR="${JENKINS_AGENT_DIR:-${JENKINS_HOME_DIR}/agent}"
DOCKER_GID="${DOCKER_GID:-998}"

export DEBIAN_FRONTEND=noninteractive

echo "[1/8] Updating apt repositories"
apt-get update

echo "[2/8] Installing base packages"
apt-get install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  jq \
  lsb-release \
  openssh-client \
  software-properties-common \
  unzip \
  wget \
  openjdk-21-jre-headless

echo "[3/8] Installing Docker Engine and Compose plugin"
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[4/8] Configuring Docker daemon"
install -d /etc/docker
cat >/etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "features": {
    "buildkit": true
  }
}
EOF

systemctl enable docker
systemctl restart docker

echo "[5/8] Ensuring jenkins user exists"
if ! getent group "${JENKINS_GROUP}" >/dev/null; then
  groupadd --system "${JENKINS_GROUP}"
fi

if ! id -u "${JENKINS_USER}" >/dev/null 2>&1; then
  useradd --create-home --home-dir "${JENKINS_HOME_DIR}" --shell /bin/bash --gid "${JENKINS_GROUP}" "${JENKINS_USER}"
fi

if ! getent group docker >/dev/null; then
  groupadd -g "${DOCKER_GID}" docker
fi

usermod -aG docker "${JENKINS_USER}"

echo "[6/8] Preparing agent directories"
install -d -o "${JENKINS_USER}" -g "${JENKINS_GROUP}" "${JENKINS_AGENT_DIR}"
install -d -o "${JENKINS_USER}" -g "${JENKINS_GROUP}" "${JENKINS_HOME_DIR}/.ssh"
chmod 700 "${JENKINS_HOME_DIR}/.ssh"

echo "[7/8] Verifying runtime dependencies"
java -version
docker version
docker compose version
git --version

echo "[8/8] Final notes"
cat <<EOF

Jenkins agent preparation completed.

Configured user:
  user: ${JENKINS_USER}
  home: ${JENKINS_HOME_DIR}
  agent dir: ${JENKINS_AGENT_DIR}

Next steps:
1. Add this host as a Jenkins agent (SSH or inbound).
2. Ensure the Jenkins user session is refreshed before testing Docker access.
3. Validate:
   sudo -iu ${JENKINS_USER} docker version
   sudo -iu ${JENKINS_USER} docker run --rm hello-world
4. Register the Multibranch Pipeline in Jenkins.

Security reminders:
- Do not store kubeconfig or GHCR tokens on disk outside Jenkins Credentials.
- Keep this agent dedicated to CI/CD if possible.
- Monitor disk usage regularly because Docker layers accumulate over time.
EOF
