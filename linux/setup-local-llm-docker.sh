#!/usr/bin/env bash
# Host provisioning only. Ollama itself is managed by the independent local-llm Compose recipe.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo bash.' >&2; exit 1; }
. /etc/os-release
[[ $ID == ubuntu && ${VERSION_CODENAME:-} == resolute ]] || { echo 'This reviewed installer targets Ubuntu 26.04 (resolute).' >&2; exit 1; }
grep -qi microsoft /proc/sys/kernel/osrelease || { echo 'This installer targets WSL2.' >&2; exit 1; }
for pkg in docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
    echo "Existing conflicting package: $pkg. Stop for review; no automatic removal." >&2; exit 1
  fi
done
# Never replace an existing repository definition without review.
for target in /etc/apt/sources.list.d/docker.sources /etc/apt/sources.list.d/nvidia-container-toolkit.list; do
  [[ ! -e $target ]] || { echo "Already exists: $target. Review before rerunning." >&2; exit 1; }
done
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat > /etc/apt/sources.list.d/docker.sources <<REPO
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: resolute
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
REPO
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey -o /tmp/local-llm-nvidia-key.asc
gpg --batch --yes --dearmor -o /etc/apt/keyrings/local-llm-nvidia.gpg /tmp/local-llm-nvidia-key.asc
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/local-llm-nvidia.gpg] https://#g' \
  > /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit
if [[ -f /etc/docker/daemon.json ]]; then
  cp -a /etc/docker/daemon.json "/etc/docker/daemon.json.before-local-llm.$(date +%Y%m%d%H%M%S)"
fi
nvidia-ctk runtime configure --runtime=docker
systemctl enable --now docker
systemctl restart docker
docker version
docker compose version
dpkg-query -W docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit
# Do not change group membership, sudoers, GPU drivers, or Codex settings.
