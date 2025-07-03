This is a learning project that deploys an infrastructure consisting of group backends,
 a database, and a Yandex load balancer. Since I specialize in devops, the backends
 and database are very simple and have no practical application. The infrastructure
 includes security groups for the backend and database, as well as the ability to
 horizontally scale the backends. Monitoring is performed from a real computer
 by recording IP addresses in the Prometheus targets. Metrics are transmitted using
 node_exporter, which is then transferred to the virtual machines. The backend image
 is built using packer and user-data.sh.
 How to use: 
 0. git clone https://github.com/Rxdeye/yc-terraform
 1. packer init ./config.pkr.hcl
 2. Build a packer image for backends.
 3. Insert packer image_id in main.tf( autoscale-group )
 4. Insert your values in variables.tf
 5. Add ssh key with name id_ed25519.pub, you can use another one, but then change the value in main.tf metadata
 6. terraform init
 7. terraform apply
 8. ansible-playbook -i inventory.ini deploy.yml
 9. Change targets in prometheus.yml
 10. in prometheus/ docker compose up -d
 11. http://localhost:3000(grafana)
 12. done!)
 utilities:
 Terraform v.1.12.1
 Ansible [ core 2.18.6 ]
 Packer v1.13.1
 Docker compose v2.36.2
