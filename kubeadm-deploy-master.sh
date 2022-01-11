#!/bin/bash

kubeadm init --apiserver-advertise-address=${MASTER_PRIVATE_IP} --apiserver-cert-extra-sans=${MASTER_PUBLIC_IP}
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubeadm token create --print-join-command > /tmp/kubeadm_join