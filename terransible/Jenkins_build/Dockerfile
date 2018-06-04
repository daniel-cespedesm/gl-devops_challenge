FROM jenkins/jenkins:latest

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt



cat config.xml | java -jar jenkins-cli.jar -s http://184.72.214.206:8081 create-node Hygieia-node --username gorilla --password GorillaLogic

<slave>
  <remoteFS>/opt/jenkins</remoteFS>
  <numExecutors>2</numExecutors>
  <launcher class="hudson.slaves.JNLPLauncher" />
  <userId>ec2-user</userId>
</slave>

java -jar agent.jar -jnlpUrl http://184.72.214.206:8081/computer/Hygieia-node/slave-agent.jnlp -jnlpCredentials gorilla:GorillaLogic &
