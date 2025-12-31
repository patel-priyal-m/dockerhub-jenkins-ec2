# Docker Compose Deployment Branch

This branch demonstrates deploying the application using **docker-compose** with multiple services.

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│         Load Balancer (Port 80)     │
├─────────────────────────────────────┤
│  Web App (Nginx + Static HTML)      │
├─────────────────────────────────────┤
│  Redis Cache (Alpine)                │
├─────────────────────────────────────┤
│  Monitor (Status Page - Port 8080)   │
└─────────────────────────────────────┘
```

## 📦 Services

1. **web** - Main application (port 80)
2. **redis** - Redis cache for demonstration
3. **monitor** - Health monitoring page (port 8080)

## 🚀 Local Testing

```bash
# Build and start all services
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

**Access:**
- Main App: http://localhost
- Monitor: http://localhost:8080

## 🔧 Jenkins Deployment

The Jenkinsfile supports both deployment methods:

### Single Container (main branch)
```
ACTION = deploy (single container)
```

### Docker Compose (this branch)
```
ACTION = deploy-compose (multi-container stack)
```

## 📋 Deployment Comparison

| Feature | Single Container | Docker Compose |
|---------|-----------------|----------------|
| Services | 1 (web only) | 3 (web, redis, monitor) |
| Complexity | Simple | Moderate |
| Scalability | Manual | Easy with `scale` |
| Networking | Host network | Bridge network |
| Health Check | Manual | Built-in monitor |
| Use Case | Simple apps | Microservices |

## 🎯 Use Cases for Docker Compose

1. **Multi-tier Applications** - Frontend + Backend + Database
2. **Microservices** - Multiple interconnected services
3. **Development Environments** - Consistent setup across team
4. **Service Dependencies** - Automatic service linking
5. **Volume Management** - Shared data between containers

## 🔄 Scaling Services

```bash
# Scale web service to 3 instances
docker-compose up -d --scale web=3

# Scale down
docker-compose up -d --scale web=1
```

## 📊 Monitoring

- **Main App**: http://EC2-IP:80
- **Monitor Dashboard**: http://EC2-IP:8080
- **View logs**: `docker-compose logs -f web`

## 🛠️ Configuration

Edit `docker-compose.yml` to:
- Add more services (database, API, etc.)
- Configure environment variables
- Set resource limits
- Add volumes for persistence

## 💡 Benefits of This Approach

✅ **Single command deployment** - `docker-compose up -d`
✅ **Service isolation** - Each service in own container
✅ **Easy networking** - Services communicate by name
✅ **Quick rollback** - `docker-compose down && docker-compose up -d`
✅ **Environment consistency** - Same setup dev to prod
