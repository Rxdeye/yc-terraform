[Services]
vm1-postgres ansible_host="${ vm_postgres.network_interface[0].nat_ip_address }"
[Services:vars]
database_data_path="path/to/init.sql"
docker_compose1="path/to/postgre/docker-compose"
docker_compose2="path/to/node/docker-compose"
[all:vars]
ansible_user=ubuntu
% { endfor ~}


