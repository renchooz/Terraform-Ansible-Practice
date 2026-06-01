%{ for group in distinct([for name, server in servers : server.os_group]) ~}
[${group}]
%{ for name, instance in workers ~}
%{ if servers[name].os_group == group ~}
${name} ansible_host=${instance.public_ip} ansible_user=${servers[name].ssh_user} ansible_python_interpreter=${servers[name].python_path}
%{ endif ~}
%{ endfor ~}

%{ endfor ~}
[workers:children]
%{ for group in distinct([for name, server in servers : server.os_group]) ~}
${group}
%{ endfor ~}

[all:vars]
ansible_ssh_private_key_file=${ssh_key_path}