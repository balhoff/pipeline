pipeline {
    agent {
        docker {
            image 'phenoscape/pipeline-tools:v1.0.4'
            label 'zeppo'
            args '-u root:root'
        }
    }
     stages {
         stage('Build') {
             steps {
                    sh "whoami"
                    sh "env" 
                    sh "groups"
                    sh "pwd"
                    sh "ls -AlF"
                    sh "if [ ! -d phenoscape-data ]; then git clone --depth 1 https://github.com/phenoscape/phenoscape-data.git; fi"
                    sh 'make all'
             }
         }
     }
 }
