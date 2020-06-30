# https://number1.co.za/managing-lxc-lxd-linux-containers-with-terraform/
# provider to connect to infrastructure

variable "lxdServer" {}
variable "sshPubicKey" {}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  lxd_remote {
    name     = "me"
    scheme   = "https"
    address  = var.lxdServer
    password = "pass"
    default  = true
  }
}

resource "lxd_container" "hosting" {
  config           = {
    "security.nesting" = "true"
  }
  ephemeral        = false
  name             = "hosting"
  profiles         = ["default"]
  image            = "images:ubuntu/18.04"
  wait_for_network = true

  provisioner "local-exec" {
    command = <<EOF
    lxc exec hosting -- sh -c "mkdir /root/.ssh"
    lxc exec hosting -- sh -c "echo '${var.sshPubicKey}' >> /root/.ssh/authorized_keys"
    lxc exec hosting -- sh -c "apt update && apt -y install openssh-server openssh-sftp-server python"
    EOF
  }
}

output "servers" {
  value = {
    hosting     = lxd_container.hosting.ip_address
  }
}
