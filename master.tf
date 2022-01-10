resource "digitalocean_droplet" "k8s_master" {
    image = "debian-11-x64"
    name = "k8s-test-master"
    size = "s-2vcpu-4gb"
    region = "fra1"
    ssh_keys = [ var.ssh_key_id ]
    #user_data = "${file("required-user-data.sh")}"

    provisioner "file" {
        source = "./required-user-data.sh"
        destination = "/tmp/required-user-data.sh"
        connection {
            type = "ssh"
            host = "${self.ipv4_address}"
            user = "root"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }

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

    # Necessary changes like cgroupv2, modules and sysctl configuration (requires a reboot)
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/required-user-data.sh",
            "/tmp/required-user-data.sh"
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
            sleep 120
            while ! ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${self.ipv4_address}
            do
                echo "Waiting for ${self.ipv4_address} to respond"
                sleep 5
            done
        EOF

    }

    # Deploy the cluster with kubeadm
    provisioner "remote-exec" {
        inline = [
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
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa root@${self.ipv4_address}:/etc/kubernetes/admin.conf ${path.module}/admin.conf.privateip
            sed -e 's/${self.ipv4_address_private}/${self.ipv4_address}/' ${path.module}/admin.conf.privateip > ${path.module}/admin.conf.privateip
        EOF  
    }
}

