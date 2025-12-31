# Simple Demo App - Jenkins CI/CD Pipeline

A lightweight static HTML application deployed via Jenkins to AWS EC2 using Docker.

## 🚀 Features

- **Ultra-lightweight**: Static HTML with nginx (only ~5MB Docker image)
- **Perfect for AWS Free Tier**: Minimal resource usage
- **CI/CD with Jenkins**: Automated build and deployment
- **DockerHub Integration**: Automated image push
- **Easy Deployment**: Single command deployment to EC2

## 📋 Prerequisites

### Local Machine
- Docker installed
- Make utility
- Git

### Jenkins Server
- Docker installed
- SSH access to EC2 instance
- Jenkins credentials configured (see Setup section)

### AWS EC2 Instance
- Running instance (t2.micro free tier works perfectly)
- Docker installed
- SSH access configured
- Security group allowing inbound traffic on port 80

## 🛠️ Setup Instructions

### 1. Configure Makefile Variables

Edit `Makefile` and update:
```makefile
DOCKER_USERNAME = your-dockerhub-username
EC2_HOST = your-ec2-ip-address
SSH_KEY = ~/.ssh/your-key.pem
```

### 2. Jenkins Credentials Setup

Add these credentials in Jenkins (Manage Jenkins → Credentials):

1. **DockerHub Credentials**
   - ID: `dockerhub-username` (Username)
   - ID: `dockerhub-password` (Secret text)

2. **EC2 Host**
   - ID: `ec2-host` (Secret text)
   - Value: Your EC2 instance public IP or DNS

3. **EC2 SSH Key**
   - ID: `ec2-ssh-key` (SSH Username with private key)
   - Username: `ec2-user`
   - Private Key: Your EC2 .pem file content

### 3. EC2 Instance Preparation

SSH into your EC2 instance and install Docker:
```bash
# For Amazon Linux 2
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Re-login to apply group changes
exit
# SSH back in
```

## 📦 Usage

### Local Development & Testing

```bash
# Build Docker image locally
make build

# Test locally on port 8080
make test
# Visit: http://localhost:8080

# Clean up test container
make clean-test
```

### Using Make Commands

```bash
# 1. Build, tag and push to DockerHub only
make push

# 2. Build, push AND deploy to EC2
make deploy

# View help for all commands
make help

# Check container status on EC2
make status

# View container logs on EC2
make logs
```

### Using Jenkins Pipeline

1. **Create Jenkins Pipeline Job**
   - New Item → Pipeline
   - Pipeline definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repo URL
   - Script Path: Jenkinsfile

2. **Build with Parameters**
   - Click "Build with Parameters"
   - **ACTION**: 
     - `push` - Only builds and pushes to DockerHub
     - `deploy` - Builds, pushes, and deploys to EC2
   - **TAG**: Docker image tag (default: latest)

## 🎯 Pipeline Scenarios

### Scenario 1: Push Only (Development)
```bash
# Using Make
make push

# Using Jenkins
Select ACTION = "push" in Jenkins build parameters
```
**Use Case**: Testing Docker build, updating DockerHub image without deploying

### Scenario 2: Full Deployment (Production)
```bash
# Using Make
make deploy

# Using Jenkins
Select ACTION = "deploy" in Jenkins build parameters
```
**Use Case**: Deploy new version to EC2

### Scenario 3: Rollback
```bash
# Deploy previous version
make deploy TAG=v1.0

# Or in Jenkins, set TAG parameter to previous version
```

### Scenario 4: Multi-Environment Deployment
Modify Makefile to support multiple environments:
```bash
make deploy ENV=staging
make deploy ENV=production
```

## 🔧 Additional Scenarios

1. **Blue-Green Deployment**: Run two containers on different ports, switch traffic
2. **Health Check Integration**: Add endpoint monitoring before deployment
3. **Automated Testing**: Add test stage in Jenkinsfile
4. **Notifications**: Add Slack/Email notifications in Jenkins post-actions
5. **Image Versioning**: Auto-tag with build number or git commit hash

## 📁 Project Structure

```
demo-app/
├── index.html          # Static website
├── Dockerfile          # Docker configuration
├── Makefile           # Build and deployment automation
├── Jenkinsfile        # Jenkins pipeline definition
└── README.md          # This file
```

## 🐛 Troubleshooting

### Docker push fails
```bash
# Login manually
docker login
```

### SSH connection fails
```bash
# Test SSH connection
ssh -i ~/.ssh/your-key.pem ec2-user@your-ec2-ip

# Check security group allows SSH (port 22)
```

### Container not accessible
```bash
# Check EC2 security group allows HTTP (port 80)
# Check container is running
make status
```

## 📝 Notes

- Nginx Alpine image is only ~5MB, perfect for free tier
- Container auto-restarts on failure (`--restart unless-stopped`)
- Old containers are automatically cleaned up on deployment
- Always logout from DockerHub after pushing (security best practice)

## 🎓 Learning Resources

- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [AWS EC2 Free Tier](https://aws.amazon.com/free/)
- [Nginx Documentation](https://nginx.org/en/docs/)
