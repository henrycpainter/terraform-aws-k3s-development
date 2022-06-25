#!/bin/bash
goback=$(pwd)

until (aws --version | grep 'aws-cli/2'); do
  echo 'Installing awscli v2'
  curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update || sudo ./aws/install
  rm -rf aws awscliv2.zip
  sleep 5
done
sudo snap start amazon-ssm-agent

# Use fixed certs
#Do this if we want to keep the kubectl connection things even if we get a new instance.

INSTANCE_ID="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
REGION="$(curl http://169.254.169.254/latest/meta-data/placement/region)"
MAXWAIT=30
ALLOC_ID="${eip_id}"

# Make sure the EIP is free
echo "Checking if EIP with ALLOC_ID[$ALLOC_ID] is free...."
ISFREE=$(aws ec2 describe-addresses --allocation-ids $ALLOC_ID --query Addresses[].InstanceId --output text)
STARTWAIT=$(date +%s)
while [ ! -z "$ISFREE" ]; do
    if [ "$(($(date +%s) - $STARTWAIT))" -gt $MAXWAIT ]; then
        echo "WARNING: We waited $${MAXWAIT} seconds, we're forcing it now."
        ISFREE=""
    else
        echo "Waiting for EIP with ALLOC_ID[$ALLOC_ID] to become free...."
        sleep 3
        ISFREE=$(aws ec2 describe-addresses --allocation-ids $ALLOC_ID --query Addresses[].InstanceId --output text)
    fi
done

aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOC_ID --allow-reassociation

mkdir -p /var/lib/rancher/k3s/server/tls
cd /var/lib/rancher/k3s/server/tls

for thing in client-ca server-ca request-header-ca
do
  echo "Doing Key and Crt for $${thing}"
  #Key
  aws ssm get-parameter --name "/k3s/$${thing}-key" --with-decryption --output text --query Parameter.Value > $${thing}.key
  if ! grep -q '[^[:space:]]' "$${thing}.key"; then
      echo "key is empty"
      #Generate key
      openssl genrsa -out $${thing}.key 2048
      #Put key in param
      aws ssm put-parameter --name "/k3s/$${thing}-key" --value "`cat $${thing}.key`" --type String --overwrite
  else
      echo "Key has data"
  fi

  #Cert
  aws ssm get-parameter --name "/k3s/$${thing}-crt" --with-decryption --output text --query Parameter.Value > $${thing}.crt
  if ! grep -q '[^[:space:]]' "$${thing}.crt"; then
      echo "crt is empty"
      #Generate crt
      openssl req -x509 -new -nodes -key $${thing}.key -sha256 -days 3560 -out $${thing}.crt -addext keyUsage=critical,digitalSignature,keyEncipherment,keyCertSign -subj '/CN=k3s-$${thing}'
      #Put key in param
      aws ssm put-parameter --name "/k3s/$${thing}-crt" --value "`cat $${thing}.crt`" --type String --overwrite
  else
      echo "Crt has data"
  fi
done

cd $goback

#Installs k3s
until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v${install_k3s_version}' INSTALL_K3S_EXEC='${k3s_tls_san} ${k3s_exec}' K3S_TOKEN='${k3s_cluster_secret}' K3S_URL='https://${k3s_url}:6443' sh -); do
  echo 'k3s did not install correctly. Trying more.'
  sleep 2
done

until kubectl get pods -A | grep 'Running'; do
  echo 'Waiting for k3s startup'
  sleep 5
done

split -n 2 /etc/rancher/k3s/k3s.yaml
aws ssm put-parameter --name "/k3s/kubeconfig/1" --value "`cat xaa`" --type String --overwrite
aws ssm put-parameter --name "/k3s/kubeconfig/2" --value "`cat xab`" --type String --overwrite