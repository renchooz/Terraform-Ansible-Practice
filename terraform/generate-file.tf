resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    workers      = aws_instance.servers
    servers      = var.servers
    ssh_key_path = var.ssh_key_path
  })
}

resource "local_file" "ansible_cfg" {
  filename = "../ansible/ansible.cfg"

  content = templatefile("${path.module}/ansible.cfg.tpl", {
    inventory_file = "inventory.ini"
    key_file       = "./ansible-key"
  })
}