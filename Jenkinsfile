pipeline {
    agent {
        dockerfile {
            filename 'Dockerfile'
            label 'zeppo'
            args '-u root:root'
        }
    }
     stages {
         stage('Build') {
             steps {
                    echo "test print: make all"
                    sh "whoami"
                    sh "env" 
                    sh "groups"
                    sh "pwd"
                    sh "ls -AlF"
                    sh 'make all'
             }
         }
         stage('Test') {
             steps {
                    sh 'make test'
             }
         }
         stage('Deploy') {
             steps {
                 sh 'make publish'
             }
         }
     }

 }
