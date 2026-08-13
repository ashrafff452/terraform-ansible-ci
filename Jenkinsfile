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
                    sh '''
                        terraform init
                    '''
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
        withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding',
             credentialsId: 'aws_id']
        ]) {
            sh '''
                aws sts get-caller-identity

                cd terraform
                terraform init
                terraform plan
            '''
        }
    }
}
        stage('Terraform Apply') {
    steps {
        withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding',
             credentialsId: 'aws_id']
        ]) {
            sh '''
                aws sts get-caller-identity

                cd terraform
                terraform init
                terraform apply -auto-approve
            '''
        }
    }
}
        stage('Generate Ansible Inventory') {
            steps {

                dir("${TF_DIR}") {

                    script {

                        def amazonIP = sh(
                            script: "terraform output -raw amazon_linux_public_ip",
                            returnStdout: true
                        ).trim()

                        def ubuntuIP = sh(
                            script: "terraform output -raw ubuntu_public_ip",
                            returnStdout: true
                        ).trim()

                        writeFile(
                            file: "../ansible/inventory",
                            text: """
[amazon]
c8.local ansible_host=${amazonIP} ansible_user=ec2-user ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/linux_testing.pem

[ubuntu]
u21.local ansible_host=${ubuntuIP} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/linux_testing.pem
"""
                        )
                    }
                }
            }
        }

        stage('Ansible Ping') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        ansible all -m ping
                    '''
                }
            }
        }

        stage('Configure VMs') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        ansible-playbook playbooks/site.yml
                    '''
                }
            }
        }

        stage('Verification') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        ansible all -a "hostname"
                        ansible all -a "systemctl is-active httpd || systemctl is-active apache2"
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
