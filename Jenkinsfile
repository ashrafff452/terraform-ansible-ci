pipeline {

    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'

        TF_DIR      = 'terraform'
        ANSIBLE_DIR = 'ansible'

        AWS_CREDENTIALS = 'aws_id'

        SSH_KEY = '/var/lib/jenkins/.ssh/linux_test.pem'
    }

    stages {

        /*
         * ==========================================================
         * 1. CHECKOUT
         * ==========================================================
         */

        stage('Checkout') {
            steps {
                checkout scm
            }
        }


        /*
         * ==========================================================
         * 2. TERRAFORM INIT
         * ==========================================================
         */

        stage('Terraform Init') {
            steps {

                dir("${TF_DIR}") {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: "${AWS_CREDENTIALS}"]
                    ]) {

                        sh '''
                            set -e

                            echo "======================================"
                            echo "AWS IDENTITY"
                            echo "======================================"

                            aws sts get-caller-identity

                            echo "======================================"
                            echo "TERRAFORM INIT"
                            echo "======================================"

                            terraform init
                        '''
                    }
                }
            }
        }


        /*
         * ==========================================================
         * 3. TERRAFORM VALIDATE
         * ==========================================================
         */

        stage('Terraform Validate') {
            steps {

                dir("${TF_DIR}") {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "TERRAFORM VALIDATE"
                        echo "======================================"

                        terraform validate
                    '''
                }
            }
        }


        /*
         * ==========================================================
         * 4. TERRAFORM PLAN
         * ==========================================================
         */

        stage('Terraform Plan') {
            steps {

                dir("${TF_DIR}") {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: "${AWS_CREDENTIALS}"]
                    ]) {

                        sh '''
                            set -e

                            echo "======================================"
                            echo "AWS IDENTITY"
                            echo "======================================"

                            aws sts get-caller-identity

                            echo "======================================"
                            echo "TERRAFORM PLAN"
                            echo "======================================"

                            terraform plan
                        '''
                    }
                }
            }
        }


        /*
         * ==========================================================
         * 5. TERRAFORM APPLY
         * ==========================================================
         */

        stage('Terraform Apply') {
            steps {

                dir("${TF_DIR}") {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: "${AWS_CREDENTIALS}"]
                    ]) {

                        sh '''
                            set -e

                            echo "======================================"
                            echo "TERRAFORM APPLY"
                            echo "======================================"

                            aws sts get-caller-identity

                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }


        /*
         * ==========================================================
         * 6. GENERATE DYNAMIC ANSIBLE INVENTORY
         * ==========================================================
         *
         * Terraform outputs:
         *
         * amazon_linux_private_ip
         * ubuntu_private_ip
         *
         * These IPs are NOT hardcoded.
         *
         * c8.local -> frontend
         * u26.local -> backend
         *
         */

        stage('Generate Ansible Inventory') {

            steps {

                script {

                    echo "======================================"
                    echo "GET TERRAFORM OUTPUTS"
                    echo "======================================"


                    def amazonIP = sh(
                        script: """
                            terraform -chdir=${TF_DIR} output -raw amazon_linux_private_ip
                        """,
                        returnStdout: true
                    ).trim()


                    def ubuntuIP = sh(
                        script: """
                            terraform -chdir=${TF_DIR} output -raw ubuntu_private_ip
                        """,
                        returnStdout: true
                    ).trim()


                    if (!amazonIP) {
                        error("Amazon Linux private IP was not returned by Terraform")
                    }

                    if (!ubuntuIP) {
                        error("Ubuntu private IP was not returned by Terraform")
                    }


                    echo "Amazon Linux Private IP: ${amazonIP}"
                    echo "Ubuntu Private IP: ${ubuntuIP}"


                    /*
                     * IMPORTANT:
                     *
                     * Groovy variables are inserted here using
                     * ${amazonIP} and ${ubuntuIP}.
                     *
                     * We are NOT using $AMAZON_IP inside the
                     * Groovy script.
                     */


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
          ansible_ssh_private_key_file: ${SSH_KEY}

    backend:
      hosts:
        u26.local:
          ansible_host: ${ubuntuIP}
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ${SSH_KEY}

  vars:
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
"""
                    )


                    echo "======================================"
                    echo "GENERATED ANSIBLE INVENTORY"
                    echo "======================================"


                    sh """
                        cat ${ANSIBLE_DIR}/inventory.yml
                    """
                }
            }
        }


        /*
         * ==========================================================
         * 7. TEST ANSIBLE INVENTORY
         * ==========================================================
         */

        stage('Ansible Inventory Test') {

            steps {

                dir("${ANSIBLE_DIR}") {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "ANSIBLE INVENTORY"
                        echo "======================================"

                        ansible-inventory \
                            -i inventory.yml \
                            --graph

                        echo "======================================"
                        echo "ANSIBLE INVENTORY --LIST"
                        echo "======================================"

                        ansible-inventory \
                            -i inventory.yml \
                            --list
                    '''
                }
            }
        }


        /*
         * ==========================================================
         * 8. WAIT FOR SSH
         * ==========================================================
         *
         * Sometimes Terraform creates the EC2 instance before
         * SSH service is completely ready.
         *
         * This avoids the:
         *
         * Connection refused
         * Connection timed out
         *
         * problem immediately after Terraform Apply.
         */

        stage('Wait for SSH') {

            steps {

                dir("${ANSIBLE_DIR}") {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "WAITING FOR SSH"
                        echo "======================================"

                        for i in $(seq 1 30)
                        do

                            echo "SSH attempt $i/30"

                            if ansible all \
                                -i inventory.yml \
                                -m ping
                            then

                                echo "======================================"
                                echo "SSH IS READY"
                                echo "======================================"

                                break

                            fi

                            if [ "$i" -eq 30 ]
                            then

                                echo "SSH connection failed after 30 attempts"
                                exit 1
                            fi

                            sleep 10

                        done
                    '''
                }
            }
        }


        /*
         * ==========================================================
         * 9. ANSIBLE PING
         * ==========================================================
         */

        stage('Ansible Ping') {

            steps {

                dir("${ANSIBLE_DIR}") {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "ANSIBLE PING"
                        echo "======================================"

                        ansible all \
                            -i inventory.yml \
                            -m ping
                    '''
                }
            }
        }


        /*
         * ==========================================================
         * 10. CONFIGURE VMS
         * ==========================================================
         *
         * site.yml should:
         *
         * All VMs:
         *   - Disable SELinux
         *   - Disable firewalld
         *
         * Frontend:
         *   - Install nginx
         *   - Configure nginx
         *   - Proxy port 80 -> backend:19999
         *
         * Backend:
         *   - Install Netdata
         *   - Run Netdata on port 19999
         */

        stage('Configure VMs') {

            steps {

                dir("${ANSIBLE_DIR}") {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "ANSIBLE PLAYBOOK"
                        echo "======================================"

                        ansible-playbook \
                            -i inventory.yml \
                            site.yml
                    '''
                }
            }
        }


        /*
         * ==========================================================
         * 11. VERIFICATION
         * ==========================================================
         */

        stage('Verification') {

            steps {

                dir("${ANSIBLE_DIR}") {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "HOSTNAMES"
                        echo "======================================"

                        ansible all \
                            -i inventory.yml \
                            -a "hostname"


                        echo "======================================"
                        echo "SELINUX"
                        echo "======================================"

                        ansible all \
                            -i inventory.yml \
                            -m shell \
                            -a "getenforce || true"


                        echo "======================================"
                        echo "FIREWALLD"
                        echo "======================================"

                        ansible all \
                            -i inventory.yml \
                            -m shell \
                            -a "systemctl is-active firewalld || true"


                        echo "======================================"
                        echo "NGINX - FRONTEND"
                        echo "======================================"

                        ansible frontend \
                            -i inventory.yml \
                            -m shell \
                            -a "systemctl is-active nginx"


                        echo "======================================"
                        echo "NETDATA - BACKEND"
                        echo "======================================"

                        ansible backend \
                            -i inventory.yml \
                            -m shell \
                            -a "systemctl is-active netdata"


                        echo "======================================"
                        echo "NETDATA PORT 19999"
                        echo "======================================"

                        ansible backend \
                            -i inventory.yml \
                            -m shell \
                            -a "ss -lntp | grep 19999"


                        echo "======================================"
                        echo "NGINX PORT 80"
                        echo "======================================"

                        ansible frontend \
                            -i inventory.yml \
                            -m shell \
                            -a "ss -lntp | grep ':80'"


                        echo "======================================"
                        echo "NGINX -> NETDATA"
                        echo "======================================"

                        ansible frontend \
                            -i inventory.yml \
                            -m shell \
                            -a "curl -I --max-time 10 http://localhost"


                        echo "======================================"
                        echo "VERIFICATION COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }
    }


    /*
     * ==========================================================
     * POST ACTIONS
     * ==========================================================
     */

    post {

        success {

            echo '''
========================================
PIPELINE SUCCESS
========================================

Terraform:
  EC2 instances deployed successfully.

Ansible:
  Inventory generated dynamically.
  c8.local -> frontend
  u26.local -> backend

Configuration:
  SELinux handled
  firewalld handled
  Nginx configured
  Netdata configured

Verification:
  Completed successfully.
========================================
'''
        }


        failure {

            echo '''
========================================
PIPELINE FAILED
========================================

Check the Jenkins console output for
the failed stage and error message.
========================================
'''
        }
    }
}
