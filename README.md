# How To Automate Jenkins Setup with Docker and Jenkins Configuration as Code

## 📋 Overview

This repository demonstrates how to automate Jenkins setup using Docker and Jenkins Configuration as Code (JCasC). It provides a fully automated, reproducible Jenkins environment that can be deployed in minutes without any manual configuration through the web UI.

## 🎯 What is Jenkins Configuration as Code?

Jenkins Configuration as Code (JCasC) is a plugin that allows you to define Jenkins configuration in YAML files. This approach transforms Jenkins from a manually configured server into a fully automated, version-controlled infrastructure component.

### Advantages of Using Configuration as Code

1. **Reproducibility**: Deploy identical Jenkins instances across different environments (dev, staging, production) with the same configuration.

2. **Version Control**: Store your Jenkins configuration in Git, enabling:
   - Configuration history tracking
   - Easy rollback to previous configurations
   - Peer review through pull requests
   - Audit trail of all changes

3. **Automation**: Eliminate manual setup steps:
   - No clicking through the setup wizard
   - No manual plugin installation
   - No manual user creation
   - No manual security configuration

4. **Disaster Recovery**: Restore Jenkins to a working state quickly after failures by simply redeploying the container.

5. **Testing**: Test configuration changes in isolated environments before applying them to production.

6. **Documentation**: YAML configuration files serve as living documentation of your Jenkins setup.

7. **Onboarding**: New team members can understand the entire Jenkins configuration by reading YAML files instead of exploring the UI.

8. **Security**: Store sensitive values (passwords, API tokens) as environment variables instead of hardcoding them in configuration files.

## 🐳 Dockerfile Breakdown

The `Dockerfile` in this repository creates a custom Jenkins image with pre-installed plugins and JCasC configuration. Here's what each section does:

### Base Image
```dockerfile
FROM jenkins/jenkins:lts-jdk17
```
- Uses the official Jenkins LTS (Long Term Support) image with Java 17
- Provides a stable, production-ready foundation

### Java Optimization
```dockerfile
ARG JAVA_OPTS="-Xms1g -Xmx3g -XX:+UseG1GC"
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false ${JAVA_OPTS}"
```
- Sets initial heap memory to 1GB (`-Xms1g`)
- Sets maximum heap memory to 3GB (`-Xmx3g`)
- Enables G1 Garbage Collector for better performance
- **Disables the setup wizard** (`-Djenkins.install.runSetupWizard=false`) - crucial for automation!

### System Dependencies
```dockerfile
USER root
RUN apt-get update && apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*
```
- Switches to root user to install system packages
- Installs Git (for SCM operations) and curl (for API calls)
- Cleans up apt cache to reduce image size

### JCasC Configuration Directory
```dockerfile
RUN mkdir -p /var/jenkins_casc/config/ && chown -R jenkins:jenkins /var/jenkins_casc/config/
COPY jcasc/*.yaml /var/jenkins_casc/config/ 
ENV CASC_JENKINS_CONFIG=/var/jenkins_casc/config/
```
- Creates a dedicated directory for JCasC configuration files
- Copies all YAML files from the `jcasc/` folder into the container
- Sets the `CASC_JENKINS_CONFIG` environment variable to tell Jenkins where to find configuration files

### Plugin Installation
```dockerfile
USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/plugins.txt
```
- Switches back to jenkins user for security
- Copies the plugin list file
- Uses `jenkins-plugin-cli` to install all plugins automatically (with dependencies)

### Network Configuration
```dockerfile
EXPOSE 8080
```
- Exposes port 8080 for Jenkins web interface

## 📁 JCasC Configuration Files

The `jcasc/` folder contains YAML files that define different aspects of Jenkins configuration:

### `general.yaml` - General Jenkins Settings
Configures basic Jenkins settings:
- **Jenkins URL**: Sets the root URL for Jenkins (supports environment variables)
- **Admin Email**: Configures the administrator email address for notifications

### `security.yaml` - Security & User Management
Defines authentication and authorization:
- **Security Realm**: Configures local user database with predefined users
  - Admin user with full permissions
  - Developer user with limited permissions
- **Authorization Strategy**: Uses matrix-based security to define granular permissions
  - Admin gets all permissions
  - Authenticated users get read access
  - Developer gets build and read permissions for jobs
- **Environment Variables**: Passwords are injected via environment variables (`${ADMIN_PASSWORD}`, `${DEVELOPER_PASS}`)

### `credentials.yaml` - Credentials Management
Manages Jenkins credentials:
- **Username/Password Credentials**: Example database credentials
- **Environment Variable Integration**: Sensitive values (username, password) are loaded from environment variables
- **Scope**: Credentials are globally available across all jobs

## 🐋 Docker Compose Configuration

The `docker-compose.yml` file orchestrates the Jenkins container deployment:

### Service Definition
```yaml
services:
  jenkins:
```
Defines a single service named "jenkins"

### Build Configuration
```yaml
build: 
  context: .
  dockerfile: Dockerfile
  args:
    JAVA_OPTS: '-Xms1g -Xmx3g -XX:+UseG1GC'
```
- Builds the image from the current directory using the Dockerfile
- Passes Java optimization arguments to the build process

### Image and Container Naming
```yaml
image: jenkins-custom:latest
container_name: jenkins-custom
```
- Tags the built image as `jenkins-custom:latest`
- Names the running container `jenkins-custom`

### Port Mapping
```yaml
ports:
  - "8080:8080"
```
- Maps host port 8080 to container port 8080
- Access Jenkins at `http://localhost:8080`

### Persistent Data
```yaml
volumes:
  - ./jenkins_data:/var/jenkins_home
```
- Mounts `jenkins_data/` folder to persist Jenkins data (jobs, builds, configurations)
- Ensures data survives container restarts

### Resource Limits
```yaml
mem_limit: 4g
cpus: 2.0
```
- Limits container to 4GB of RAM
- Restricts container to 2 CPU cores
- Prevents Jenkins from consuming all system resources

### Restart Policy
```yaml
restart: unless-stopped
```
- Automatically restarts the container if it crashes
- Won't restart if manually stopped

### Environment Variables
```yaml
environment:      
  - JENKINS_URL=http://localhost:8080/
  - ADMIN_PASSWORD=admin123
  - DEVELOPER_PASS=devpass123
  - DB_USERNAME=dbuser
  - DB_PASSWORD=dbpass123
```
- Injects configuration values used by JCasC files
- **⚠️ SECURITY NOTE**: In production, use Docker secrets or external secret management instead of plaintext passwords

## 🚀 Getting Started

### Prerequisites
- Docker installed
- Docker Compose installed

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jenkins-docker-demo
   ```

2. **Start Jenkins**
   ```bash
   docker-compose up -d
   ```

3. **Access Jenkins**
   - Open your browser and navigate to `http://localhost:8080`
   - Login with default credentials:
     - **Admin**: username: `admin`, password: `admin123`
     - **Developer**: username: `developer`, password: `devpass123`

4. **Stop Jenkins**
   ```bash
   docker-compose down
   ```

### Customization

1. **Modify JCasC Configuration**: Edit YAML files in the `jcasc/` folder
2. **Add Plugins**: Update `plugins.txt` with additional plugins
3. **Change Environment Variables**: Edit the `environment` section in `docker-compose.yml`
4. **Rebuild**: Run `docker-compose up -d --build` to apply changes

## 📦 Included Plugins

The `plugins.txt` file includes essential plugins for modern Jenkins usage:

- **Core**: Git, Pipeline, Credentials, SSH Agent
- **SCM**: GitHub, GitLab integrations
- **Automation**: Job DSL, Configuration as Code
- **DevOps Tools**: Docker, Kubernetes, Terraform, Ansible
- **UI Enhancements**: Timestamps, ANSI colors, rebuild button

## 🔒 Security Best Practices

For production use, consider these improvements:

1. **Use Docker Secrets** instead of environment variables for passwords
2. **Enable HTTPS** with a reverse proxy (nginx, traefik)
3. **Change default passwords** before deployment
4. **Implement network segmentation** using Docker networks
5. **Regular updates** of Jenkins and plugins
6. **Enable audit logging** for compliance

## 📚 Additional Resources

- [Jenkins Configuration as Code Documentation](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Jenkins Official Docker Image](https://hub.docker.com/r/jenkins/jenkins)
- [Jenkins Plugin Index](https://plugins.jenkins.io/)

## 🤝 Contributing

Feel free to submit issues or pull requests to improve this example.

## 📄 License

This project is provided as-is for educational purposes.


