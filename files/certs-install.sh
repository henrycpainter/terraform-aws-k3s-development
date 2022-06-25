#!/bin/bash
%{ if install_certmanager }
kubectl create namespace cert-manager
sleep 5
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v${certmanager_version}/cert-manager.yaml

until [ "$(kubectl get pods --namespace cert-manager | grep Running | wc -l)" = "3" ]; do
  sleep 2
done
%{ endif }
