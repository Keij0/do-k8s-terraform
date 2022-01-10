resource "digitalocean_droplet" "k8s_workers" {
    count = 2
    image = "debian-11-x64"
    name = "k8s-test-worker-${count.index}"
    size = "s-2vcpu-4gb"
    region = "fra1"
    ssh_keys = [ var.ssh_key_id ]
    user_data = "${file("required-user-data.sh")}"
    depends_on = [ digitalocean_droplet.k8s_master ]
}