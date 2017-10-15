resource "null_resource" "ansible_init" {
  depends_on = ["null_resource.ansible_group_vars"]
  count = 0
  
  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/${var.swarm_environment} ansible/swarm.plbk"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/${var.swarm_environment} ansible/training.plbk"
  }
}
