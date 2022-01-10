output "k8s_master_ip" {
    description = "IPv4 of k8s master"
    value = digitalocean_droplet.k8s_master.ipv4_address
}

output "k8s_worker_ips" {
    description = "IPv4 of k8s worker nodes"
    value = [for instance in digitalocean_droplet.k8s_workers : instance.ipv4_address]
}