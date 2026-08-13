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
                        text: """all:
  children:
    amazon:
      hosts:
        c8.local:
          ansible_host: ${amazonIP}
          ansible_user: ec2-user
          ansible_ssh_private_key_file: /var/lib/jenkins/.ssh/linux_test.pem

    ubuntu:
      hosts:
        u21.local:
          ansible_host: ${ubuntuIP}
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /var/lib/jenkins/.ssh/linux_test.pem
"""
                    )

                    echo "===== Generated Ansible Inventory ====="

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
                        echo "===== HOSTNAMES ====="
                        ansible all -i inventory.yml -a "hostname"

                        echo "===== APACHE STATUS ====="
                        ansible all -i inventory.yml -a "systemctl is-active httpd || systemctl is-active apache2"
                    '''
                }
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
