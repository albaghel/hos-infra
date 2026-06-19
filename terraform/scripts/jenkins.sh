#!/usr/bin/env bash
# ==============================================================
# Jenkins Bootstrap — Amazon Linux 2
# ==============================================================
# Installs Jenkins LTS, Java 17, and Git.
# Runs once on first boot via EC2 user_data.
# ==============================================================

set -euo pipefail

log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"; }

# --- System update ---
log "Updating system packages..."
yum update -y

# --- Java 17 (required by Jenkins LTS) ---
log "Installing Java 17..."
yum install -y java-17-amazon-corretto-headless

# --- Git ---
yum install -y git

# --- Jenkins repository ---
log "Adding Jenkins repository..."
wget -q -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# --- Jenkins installation ---
log "Installing Jenkins..."
yum install -y jenkins

# --- Format and mount the data volume (/dev/xvdb → /var/lib/jenkins) ---
# Wait for the EBS volume to be attached before formatting.
if [ -b /dev/xvdb ]; then
  log "Formatting and mounting /dev/xvdb as /var/lib/jenkins..."
  mkfs.xfs /dev/xvdb
  mkdir -p /var/lib/jenkins
  mount /dev/xvdb /var/lib/jenkins
  # Persist the mount across reboots.
  echo "/dev/xvdb /var/lib/jenkins xfs defaults,nofail 0 2" >> /etc/fstab
fi

chown -R jenkins:jenkins /var/lib/jenkins

# --- Enable and start Jenkins ---
log "Enabling and starting Jenkins service..."
systemctl enable jenkins
systemctl start jenkins

# --- Wait for Jenkins to come online ---
log "Waiting for Jenkins to start..."
timeout 120 bash -c 'until systemctl is-active --quiet jenkins; do sleep 5; done'

log "Jenkins bootstrap complete."
log "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
log "Initial admin password: $(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'not yet generated')"
