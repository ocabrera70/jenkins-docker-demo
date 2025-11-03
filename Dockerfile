# Using the official Jenkins LTS image with JDK 17
FROM jenkins/jenkins:lts-jdk17

# JAVA_OPTS to optimize Jenkins performance
ARG JAVA_OPTS="-Xms1g -Xmx3g -XX:+UseG1GC"
# Disable the initial setup wizard of Jenkins
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false ${JAVA_OPTS}"

# Switch to root user to install additional packages
USER root
# Install necessary packages
RUN apt-get update && apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*

#Create directory for JCasC configuration files
RUN mkdir -p /var/jenkins_casc/config/ && chown -R jenkins:jenkins /var/jenkins_casc/config/
# Copy JCasC configuration files
COPY jcasc/*.yaml /var/jenkins_casc/config/ 
# Set environment variable for JCasC
ENV CASC_JENKINS_CONFIG=/var/jenkins_casc/config/

# Switch back to the jenkins user
USER jenkins

#Copy Plugins.txt file
COPY plugins.txt /usr/share/jenkins/plugins.txt
# Install plugins from plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/plugins.txt

# Expose Jenkins port
EXPOSE 8080