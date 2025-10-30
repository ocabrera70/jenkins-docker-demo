# Using the official Jenkins LTS image with JDK 17
FROM jenkins/jenkins:lts-jdk17
# Disable the initial setup wizard of Jenkins
ENV JAVA_OPTS=-Djenkins.install.runSetupWizard=false

# Switch to root user to install additional packages
USER root
# Install necessary packages
RUN apt-get update && apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*

# Switch back to the jenkins user
USER jenkins

#Copy Plugins.txt file
COPY plugins.txt /usr/share/jenkins/plugins.txt
# Install plugins from plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/plugins.txt

# Expose Jenkins port
EXPOSE 8080