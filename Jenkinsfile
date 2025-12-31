pipeline {
    agent any
    
    environment {
        // Docker configuration - uses existing Jenkins credentials
        DOCKER_CREDENTIALS = 'dockerhub-cred'
        IMAGE_NAME = 'simple-demo-app'
        
        // EC2 configuration - best practice: use parameters for environment-specific values
        CONTAINER_NAME = 'demo-app'
        CONTAINER_PORT = '80'
    }
    
    parameters {
        choice(name: 'ACTION', choices: ['push', 'deploy'], description: 'Select action: push (build & push only) or deploy (build, push & deploy)')
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
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDENTIALS}") {
                        def dockerHubUsername = sh(script: 'echo $DOCKER_USERNAME', returnStdout: true).trim()
                        env.DOCKER_IMAGE = "${dockerHubUsername}/${IMAGE_NAME}:${params.TAG}"
                    }
                    
                    echo "Building Docker image: ${env.DOCKER_IMAGE}"
                    sh "docker build -t ${env.DOCKER_IMAGE} ."
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    echo "Pushing ${env.DOCKER_IMAGE} to DockerHub..."
                    // Use Jenkins Docker plugin for secure authentication
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDENTIALS}") {
                        sh "docker push ${env.DOCKER_IMAGE}"
                    }
                }
            }
        }
        
        stage('Deploy to EC2') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Deploying to EC2: ${params.EC2_HOST}"
                    
                    def dockerCmd = """
                        docker stop ${CONTAINER_NAME} || true && \
                        docker rm ${CONTAINER_NAME} || true && \
                        docker pull ${env.DOCKER_IMAGE} && \
                        docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:80 --restart unless-stopped ${env.DOCKER_IMAGE} && \
                        docker ps | grep ${CONTAINER_NAME}
                    """
                    
                    // Use existing Jenkins SSH credentials
                    sshagent(['ec2-server-key']) {
                        sh "ssh -o StrictHostKeyChecking=no ${params.EC2_USER}@${params.EC2_HOST} '${dockerCmd}'"
                    }
                    
                    echo "✅ Deployment complete! App available at http://${params.EC2_HOST}"
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
