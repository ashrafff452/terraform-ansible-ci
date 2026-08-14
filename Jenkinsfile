pipeline {

    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws_id']
                    ]) {
                        sh '''
                            aws sts get-caller-identity
                            terraform init
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws_id']
                    ]) {
                        sh '''
                            aws sts get-caller-identity
                            terraform plan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws_id']
                    ]) {
                        sh '''
                            aws sts get-caller-identity
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Generate Ansible Inventory') {
    steps {
        script {

            def amazonIP = sh(
                script: "terraform -chdir=${TF_DIR} output -raw amazon_linux_private_ip",
                returnStdout: true
            ).trim()

            def ubuntuIP = sh(
                script: "terraform -chdir=${TF_DIR} output -raw ubuntu_private_ip",
                returnStdout: true
            ).trim()

            echo "Amazon Linux Private IP: ${amazonIP}"
            echo "Ubuntu Private IP: ${ubuntuIP}"

            writeFile(
                file: "${ANSIBLE_DIR}/inventory.yml",
                text: """\
all:
  children:
    frontend:
      hosts:
        c8.local:
          ansible_host: ${amazonIP}
          ansible_user: ec2-user
          ansible_ssh_private_key_file: /var/lib/jenkins/.ssh/linux_test.pem

    backend:
      hosts:
        u26.local:
          ansible_host: ${ubuntuIP}
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /var/lib/jenkins/.ssh/linux_test.pem

  vars:
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
"""
            )

            echo "===== GENERATED INVENTORY ====="

            sh """
                cat ${ANSIBLE_DIR}/inventory.yml
            """
        }
    }
}

        stage('Ansible Inventory Test') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        ansible-inventory -i inventory.yml --graph
                    '''
                }
            }
        }

        stage('Ansible Ping') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        ansible all -i inventory.yml -m ping
                    '''
                }
            }
        }

        stage('Configure VMs') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        ansible-playbook -i inventory.yml site.yml
                    '''
                }
            }
        }

        stage('Verification') {
    steps {
        dir("${ANSIBLE_DIR}") {
            sh '''
                echo "======================================"
                echo "HOSTNAMES"
                echo "======================================"

                ansible all -i inventory.yml -a "hostname"

                echo "======================================"
                echo "SELINUX"
                echo "======================================"

                ansible frontend -i inventory.yml -a "getenforce"

                echo "======================================"
                echo "FIREWALLD"
                echo "======================================"

                ansible frontend -i inventory.yml -a "systemctl is-active firewalld"

                echo "======================================"
                echo "NGINX"
                echo "======================================"

                ansible frontend -i inventory.yml -a "systemctl is-active nginx"

                echo "======================================"
                echo "NETDATA"
                echo "======================================"

                ansible backend -i inventory.yml -a "systemctl is-active netdata"

                echo "======================================"
                echo "NETDATA PORT"
                echo "======================================"

                ansible backend -i inventory.yml -a "ss -lntp | grep 19999"

                echo "======================================"
                echo "NGINX -> NETDATA"
                echo "======================================"

                ansible frontend -i inventory.yml -a "curl -I --max-time 10 http://localhost"

            '''
        }
    }
}

    post {

        success {
            echo 'Terraform deployment and Ansible configuration completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the Jenkins console output.'
        }
    }
}
