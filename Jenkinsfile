pipeline {
    agent any
    
    environment {
        // Docker configuration
        DOCKER_CREDENTIALS = 'dockerhub-cred'
        IMAGE_NAME = 'simple-demo-app'
        COMPOSE_PROJECT_NAME = 'demo-app'
        
        // Container configuration
        CONTAINER_NAME = 'demo-app'
        CONTAINER_PORT = '80'
    }
    
    parameters {
        choice(
            name: 'ACTION', 
            choices: ['push', 'deploy', 'deploy-compose'], 
            description: '''Select action:
            - push: Build & push to DockerHub only
            - deploy: Deploy single container
            - deploy-compose: Deploy with docker-compose (multi-container)'''
        )
        string(name: 'TAG', defaultValue: 'latest', description: 'Docker image tag')
        string(name: 'EC2_HOST', defaultValue: '34.235.127.234', description: 'EC2 instance IP address')
        string(name: 'EC2_USER', defaultValue: 'ec2-user', description: 'EC2 SSH user')
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
                    // Get DockerHub username from credentials
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        env.DOCKER_IMAGE = "${DOCKER_USER}/${IMAGE_NAME}:${params.TAG}"
                        echo "Building Docker image: ${env.DOCKER_IMAGE}"
                        sh "docker build -t ${env.DOCKER_IMAGE} ."
                    }
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    echo "Pushing ${env.DOCKER_IMAGE} to DockerHub..."
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            docker push ${env.DOCKER_IMAGE}
                        """
                    }
                }
            }
        }
        
        stage('Deploy Single Container') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Deploying single container to EC2: ${params.EC2_HOST}"
                    
                    def dockerCmd = """
                        docker stop ${CONTAINER_NAME} || true && \
                        docker rm ${CONTAINER_NAME} || true && \
                        docker pull ${env.DOCKER_IMAGE} && \
                        docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:80 --restart unless-stopped ${env.DOCKER_IMAGE} && \
                        docker ps | grep ${CONTAINER_NAME}
                    """
                    
                    sshagent(['ec2-server-key']) {
                        sh "ssh -o StrictHostKeyChecking=no ${params.EC2_USER}@${params.EC2_HOST} '${dockerCmd}'"
                    }
                    
                    echo "✅ Single container deployment complete!"
                    echo "App available at http://${params.EC2_HOST}"
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            when {
                expression { params.ACTION == 'deploy-compose' }
            }
            steps {
                script {
                    echo "Deploying with docker-compose to EC2: ${params.EC2_HOST}"
                    
                    sshagent(['ec2-server-key']) {
                        // Copy docker-compose files to EC2
                        sh """
                            ssh -o StrictHostKeyChecking=no ${params.EC2_USER}@${params.EC2_HOST} 'mkdir -p ~/demo-app'
                            scp -o StrictHostKeyChecking=no docker-compose.yml ${params.EC2_USER}@${params.EC2_HOST}:~/demo-app/
                            scp -o StrictHostKeyChecking=no monitor.html ${params.EC2_USER}@${params.EC2_HOST}:~/demo-app/
                        """
                        
                        // Deploy with docker-compose
                        sh """
                            ssh -o StrictHostKeyChecking=no ${params.EC2_USER}@${params.EC2_HOST} '
                                cd ~/demo-app
                                export DOCKER_IMAGE=${env.DOCKER_IMAGE}
                                docker-compose down || true
                                docker-compose pull
                                docker-compose up -d
                                docker-compose ps
                            '
                        """
                    }
                    
                    echo "✅ Docker Compose deployment complete!"
                    echo "Main App: http://${params.EC2_HOST}"
                    echo "Monitor: http://${params.EC2_HOST}:8080"
                }
            }
        }
    }
    
    post {
        success {
            script {
                def message = "✅ Pipeline completed successfully!"
                if (params.ACTION == 'push') {
                    message += "\nImage pushed: ${env.DOCKER_IMAGE}"
                } else if (params.ACTION == 'deploy') {
                    message += "\nSingle container deployed: http://${params.EC2_HOST}"
                } else if (params.ACTION == 'deploy-compose') {
                    message += "\nDocker Compose deployed:"
                    message += "\n  - Main App: http://${params.EC2_HOST}"
                    message += "\n  - Monitor: http://${params.EC2_HOST}:8080"
                }
                echo message
            }
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
