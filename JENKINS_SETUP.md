# Jenkins Setup Guide

## Prerequisites Checklist
- [ ] Jenkins installed on VM
- [ ] Docker installed on Jenkins VM
- [ ] Jenkins user added to docker group: `sudo usermod -aG docker jenkins`
- [ ] DockerHub account credentials
- [ ] EC2 instance SSH private key added on jenkins(.pem file)

## 🔧 Step-by-Step Setup

### 1. Configure Jenkins Credentials

Go to: **Jenkins Dashboard → Manage Jenkins → Credentials → System → Global credentials**

#### A. DockerHub Credentials
1. Click **Add Credentials**
2. Kind: `Username with password`
3. Scope: `Global`
4. Username: `your-dockerhub-username`
5. Password: `your-dockerhub-password`
6. ID: `dockerhub-cred` ⚠️ **Must match exactly**
7. Description: `DockerHub Login`

#### B. EC2 SSH Key
1. Click **Add Credentials**
2. Kind: `SSH Username with private key`
3. Scope: `Global`
4. ID: `ec2-server-key` ⚠️ **Must match exactly**
5. Username: `ec2-user`
6. Private Key: Click **Enter directly** → Paste your .pem file content
7. Description: `EC2 SSH Access`

### 2. Install Required Jenkins Plugins

**Manage Jenkins → Plugins → Available plugins**

Install these plugins:
- [ ] **Docker Pipeline** - For docker commands in pipeline
- [ ] **SSH Agent** - For sshagent functionality
- [ ] **Git** - For GitHub integration
- [ ] **Pipeline** - For Jenkinsfile support

Restart Jenkins after installation.

### 3. Create Jenkins Pipeline Job

1. **New Item** → Enter name: `demo-app-pipeline`
2. Select: **Pipeline**
3. Click **OK**

#### Configure Pipeline:

**Pipeline Section:**
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: `https://github.com/patel-priyal-m/dockerhub-jenkins-ec2.git`
- Branch: `*/main`
- Script Path: `Jenkinsfile`

**This project is parameterized:** (Should auto-detect from Jenkinsfile)
- ✅ ACTION (choice)
- ✅ TAG (string)
- ✅ EC2_HOST (string)
- ✅ EC2_USER (string)

4. Click **Save**

### 4. EC2 Instance Setup

SSH into your EC2 and run:

```bash
# Install Docker
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Test Docker (re-login first)
exit
# SSH back in
docker --version
docker ps

# Allow HTTP traffic
# Edit Security Group in AWS Console:
# - Add Inbound Rule: HTTP (Port 80) from 0.0.0.0/0
```

### 5. Test Jenkins Pipeline

1. Click **Build with Parameters**
2. Set parameters:
   - ACTION: `push` (for first test)
   - TAG: `latest`
   - EC2_HOST: `34.235.127.234`
   - EC2_USER: `ec2-user`
3. Click **Build**
4. Monitor: **Console Output**

### 6. First Deployment

1. **Build with Parameters**
2. Set parameters:
   - ACTION: `deploy` ⚠️
   - TAG: `latest`
   - EC2_HOST: `34.235.127.234`
   - EC2_USER: `ec2-user`
3. Click **Build**
4. After success, visit: `http://34.235.127.234`

## 🎯 Usage

### Scenario 1: Push Only (Update DockerHub)
```
ACTION = push
TAG = latest
```
**Result**: Builds and pushes to DockerHub only

### Scenario 2: Full Deployment
```
ACTION = deploy
TAG = latest
EC2_HOST = 34.235.127.234
```
**Result**: Builds, pushes, and deploys to EC2

### Scenario 3: Deploy Specific Version
```
ACTION = deploy
TAG = v1.2.3
EC2_HOST = 34.235.127.234
```
**Result**: Deploys specific tag

### Scenario 4: Deploy to Different EC2
```
ACTION = deploy
TAG = latest
EC2_HOST = different-ip-address
```
**Result**: Deploys to different server

## 🔍 Troubleshooting

### Docker Permission Denied
```bash
# On Jenkins VM
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### SSH Connection Failed
```bash
# Test SSH from Jenkins VM
ssh -i /path/to/key.pem ec2-user@34.235.127.234

# Check EC2 Security Group allows SSH (port 22) from Jenkins IP
```

### Cannot Pull from DockerHub
```bash
# On EC2 instance, test manually:
docker pull patelpriyalm/simple-demo-app:latest
```

### Container Not Accessible
```bash
# Check EC2 Security Group allows HTTP (port 80)
# Check container is running:
ssh ec2-user@34.235.127.234 "docker ps"
```

### Jenkins Can't Find Docker
```bash
# On Jenkins VM, check docker is in PATH
which docker
# Should output: /usr/bin/docker

# If not, add to Jenkins system config:
# Manage Jenkins → System → Global properties
# Environment variables: PATH=/usr/bin:$PATH
```

## 📊 Verify Setup

### On Jenkins VM:
```bash
docker --version
docker ps
ssh -i ~/.ssh/key.pem ec2-user@34.235.127.234 "echo Connection OK"
```

### On EC2 Instance:
```bash
docker --version
docker ps
curl http://localhost:80
```

### From Browser:
```
http://34.235.127.234
```

## 🚀 Next Steps

1. **Set up GitHub Webhook** - Auto-trigger build on push
   - GitHub Repo → Settings → Webhooks
   - Payload URL: `http://jenkins-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Events: `Push`

2. **Add Notifications** - Slack/Email on build status

3. **Add Testing Stage** - Run tests before deployment

4. **Set up Multiple Environments** - Dev, Staging, Prod

## 📝 Credentials Reference

| Credential ID | Type | Used In | Purpose |
|---------------|------|---------|---------|
| `dockerhub-cred` | Username/Password | Jenkinsfile | Push images to DockerHub |
| `ec2-server-key` | SSH Private Key | Jenkinsfile | Deploy to EC2 via SSH |

## ⚠️ Security Reminders

- ✅ Never commit `.pem` files to Git
- ✅ Keep Jenkins credentials encrypted
- ✅ Use Security Groups to limit EC2 access
- ✅ Rotate credentials periodically
- ✅ Use Jenkins Role-Based Access Control
