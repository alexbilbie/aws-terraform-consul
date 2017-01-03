#!/bin/bash
echo "################################################################################"
echo "# Log everything"
echo "# $(pwd)"
echo "################################################################################"

echo
echo

exec >  >(tee -a /var/log/user-script.log)
exec 2> >(tee -a /var/log/user-script.log >&2)

echo
echo

echo "################################################################################"
echo "# Set hostname"
echo "# $(pwd)"
echo "################################################################################"

echo
echo

export instanceID
instanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export HOSTNAME="consul-master-${instanceID}"
hostname "${HOSTNAME}"
echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts

echo
echo

echo "################################################################################"
echo "# Install system dependencies"
echo "# $(pwd)"
echo "################################################################################"

echo
echo

sudo locale-gen en_GB.UTF-8
apt-get update -y
apt-get install -y curl unzip python-pip
pip install awscli

echo
echo

echo "################################################################################"
echo "# Download Consul"
echo "# $(pwd)"
echo "################################################################################"

echo
echo

cd /tmp
curl -O https://releases.hashicorp.com/consul/0.7.2/consul_0.7.2_linux_amd64.zip
unzip consul_0.7.2_linux_amd64.zip
rm -f consul_0.7.2_linux_amd64.zip
chmod +x ./consul
mv /tmp/consul /usr/local/bin

echo
echo

echo "################################################################################"
echo "# Setup Consul"
echo "# $(pwd)"
echo "################################################################################"

echo
echo

export PRIVATE_IP
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
export EC2_AZ
EC2_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
export EC2_REGION
EC2_REGION="${EC2_AZ: : -1}"

adduser useradd -r -s /bin/false consul
mkdir -p /etc/consul.d/{bootstrap,server,client}
mkdir /var/consul
chown consul:consul /var/consul
chown consul:consul /opt/ui

cat <<EOF > /etc/consul.d/server/config.json
{
    "client_addr": "0.0.0.0",
    "bootstrap_expect": 3,
    "server": true,
    "datacenter": "${EC2_REGION}",
    "data_dir": "/var/consul",
    "bind_addr": "0.0.0.0",
    "advertise_addr": "${PRIVATE_IP}",
    "retry_join": []
}
EOF

cat <<EOF > /etc/init/consul
start on runlevel [2345]
respawn
respawn limit 2 5
exec sudo -u consul /usr/local/bin/consul agent -config-dir /etc/consul.d/server
EOF

initctl reload-configuration
initctl start consul

echo
echo

echo "################################################################################"
echo "# Done"
echo "################################################################################"