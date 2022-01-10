#!/bin/bash
sysctl --system

kubeadm init
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubeadm token create --print-join-command > /tmp/kubeadm_join