resource "digitalocean_droplet" "k8s_master" {
    image = "debian-11-x64"
    name = "k8s-test-master"
    size = "s-2vcpu-4gb"
    region = "fra1"
    ssh_keys = [ var.ssh_key_id ]
    #user_data = "${file("required-user-data.sh")}"

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

    # Copy kubeadm deployment script
    provisioner "file" {
        source = "./kubeadm-deploy-master.sh"
        destination = "/tmp/kubeadm-deploy-master.sh"
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }

    # Deploy the cluster with kubeadm
    provisioner "remote-exec" {
        inline = [
            "export MASTER_PRIVATE_IP=${self.ipv4_address_private}",
            "export MASTER_PUBLIC_IP=${self.ipv4_address}",
            "chmod +x /tmp/kubeadm-deploy-master.sh",
            "/tmp/kubeadm-deploy-master.sh"
        ]
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }

    # Get kubeconfig (/etc/kubernetes/admin.conf) and kubeadm join command from master
    provisioner "local-exec" {
        command = <<EOF
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa root@${self.ipv4_address}:/tmp/kubeadm_join ${path.module}/kubeadm_join
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa root@${self.ipv4_address}:/etc/kubernetes/admin.conf ${path.module}/admin.conf.orig
            sed -e 's/${self.ipv4_address_private}/${self.ipv4_address}/' ${path.module}/admin.conf.orig > ${path.module}/admin.conf
        EOF  
    }
}

