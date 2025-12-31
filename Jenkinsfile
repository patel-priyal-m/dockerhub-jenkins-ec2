pipeline {
    agent any
    
    environment {
        DOCKER_USERNAME = credentials('dockerhub-username')
        DOCKER_PASSWORD = credentials('dockerhub-password')
        IMAGE_NAME = 'simple-demo-app'
        EC2_HOST = credentials('ec2-host')
        EC2_USER = 'ec2-user'
        CONTAINER_NAME = 'demo-app'
    }
    
    parameters {
        choice(name: 'ACTION', choices: ['push', 'deploy'], description: 'Select action: push (build & push only) or deploy (build, push & deploy)')
        string(name: 'TAG', defaultValue: 'latest', description: 'Docker image tag')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_USERNAME}/${IMAGE_NAME}:${params.TAG}"
                    sh """
                        docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${params.TAG} .
                    """
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    echo 'Logging into DockerHub...'
                    sh """
                        echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
                        docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${params.TAG}
                    """
                }
            }
        }
        
        stage('Deploy to EC2') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Deploying to EC2: ${EC2_HOST}"
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                docker stop ${CONTAINER_NAME} || true
                                docker rm ${CONTAINER_NAME} || true
                                docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${params.TAG}
                                docker run -d --name ${CONTAINER_NAME} -p 80:80 --restart unless-stopped ${DOCKER_USERNAME}/${IMAGE_NAME}:${params.TAG}
                                docker ps | grep ${CONTAINER_NAME}
                            '
                        """
                    }
                    echo "Deployment complete! App available at http://${EC2_HOST}"
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
