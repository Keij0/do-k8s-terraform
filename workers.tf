resource "digitalocean_droplet" "k8s_workers" {
    count = 2
    image = "debian-11-x64"
    name = "k8s-test-worker-${count.index}"
    size = "s-2vcpu-4gb"
    region = "fra1"
    ssh_keys = [ var.ssh_key_id ]
    #user_data = "${file("required-user-data.sh")}"
    depends_on = [ digitalocean_droplet.k8s_master ]
        
    provisioner "file" {
        source = "./setup-dependencies.sh"
        destination = "/tmp/setup-dependencies.sh"
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }

    # Necessary changes like cgroupv2, modules and sysctl configuration (requires a reboot)
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/setup-dependencies.sh",
            "/tmp/setup-dependencies.sh"
        ]
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }

    # Wait for reboot
    provisioner "local-exec" {
        command = <<EOF
            sleep 90
            while ! ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${self.ipv4_address}
            do
                echo "Waiting for ${self.ipv4_address} to respond"
                sleep 5
            done
        EOF

    }

    provisioner "file" {
        source = "./kubeadm_join"
        destination = "/tmp/kubeadm_join"
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/kubeadm_join",
            "/tmp/kubeadm_join"
        ]
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }
}