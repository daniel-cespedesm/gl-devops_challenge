pipeline {
  agent master

  environment{
    MAJOR_VERSION = 1
  }

  stages {

    stage('Getting Hygieia repository') {
      steps{
        sh "git clone https://github.com/daniel-cespedesm/Hygieia.git"
        sh 'ant -f test.xml -v'
        junit 'reports/result.xml'
      }
    }

    stage('build') {
      agent {label 'apache'}
      steps{
        sh 'ant -f build.xml -v'
      }
      post {
        success {
          archiveArtifacts artifacts: 'dist/*.jar', fingerprint: true
        }
      }
    }

    stage ('deploy'){
      agent {label 'apache'}
      steps{
        sh "mkdir -p /var/www/html/rectangles/all/${env.BRANCH_NAME}"
        sh "cp dist/rectangle_${env.MAJOR_VERSION}.${env.BUILD_NUMBER}.jar /var/www/html/rectangles/all/${env.BRANCH_NAME}"
      }
    }

    stage ('Running on CentOS'){
      agent {label 'CentOS'}
      steps{
        sh "wget http://54.226.84.37/rectangles/all/${env.BRANCH_NAME}/rectangle_${env.MAJOR_VERSION}.${env.BUILD_NUMBER}.jar"
        sh "java -jar rectangle_${env.MAJOR_VERSION}.${env.BUILD_NUMBER}.jar 10 20"
      }
    }

    stage("Test on Debian"){
      agent{
        docker {
          image 'openjdk:8u121-jre'
          label 'master'
        }
      }
      steps {
        sh "wget http://54.226.84.37/rectangles/all/${env.BRANCH_NAME}/rectangle_${env.MAJOR_VERSION}.${env.BUILD_NUMBER}.jar"
        sh "java -jar rectangle_${env.MAJOR_VERSION}.${env.BUILD_NUMBER}.jar 20 25"
      }
    }

    stage ("Promote to green"){
      agent {label 'apache'}
      when {
        branch 'master'
      }
      steps{
        sh "cp /var/www/html/rectangles/all/${env.BRANCH_NAME}/rectangle_${env.MAJOR_VERSION}.${env.BUILD_NUMBER}.jar /var/www/html/rectangles/green/"
      }
    }
    stage("promote development branch to master"){
      agent {label 'apache'}
      when {
        branch 'development'
      }
      steps {
        echo "Stashing Any Local Changes"
        sh "git stash"
        echo "Checking Out Development Branch"
        sh "git checkout development"
        sh 'git pull origin'
        echo "Checking Out Master Branch"
        sh "git checkout master"
        echo "Merging Development into Master Branch"
        sh "git merge development"
        echo "Pushing to Origin Master"
        sh "git push origin master"
        echo "tagging the release"
        sh "git tag rectangle-${env.MAJOR_VERSION}.${env.BUILD_NUMBER}"
        sh "git push origin rectangle-${env.MAJOR_VERSION}.${env.BUILD_NUMBER}"
      }
      post {
        success {
          emailext(
            subject: "${env.JOB_NAME} [${env.BUILD_NUMBER}] Development Promoted to Master!",
            body: """ <p>'${env.JOB_NAME} [${env.BUILD_NUMBER}]' Development Promoted to Master!": </p>
            <Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
            to: "dacesmo@gmail.com"
            )
        }
      }
    }
  }

  post {
    failure {
      emailext(
        subject: "${env.JOB_NAME} [${env.BUILD_NUMBER}] Failed!",
        body: """ <p>'${env.JOB_NAME} [${env.BUILD_NUMBER}]' Failed": </p>
        <Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
        to: "dacesmo@gmail.com"
        )
    }
  }

}
