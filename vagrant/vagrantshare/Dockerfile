FROM jenkins/jenkins:lts-jdk11
USER root
RUN apt-get update && apt-get install -y ca-certificates curl \ 
    apt-transport-https gnupg
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
RUN AZ_REPO=$(cat /etc/os-release | egrep CODENAME | sed "s/VERSION_CODENAME=//") && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update && apt-get install -y azure-cli
USER jenkins
RUN sleep 5 && \
    jenkins-plugin-cli --plugins "blueocean:1.25.5"