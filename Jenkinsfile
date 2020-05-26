pipeline {
    agent {
        docker {
            image 'phenoscape/pipeline-tools:v1.1'
            label 'zeppo'
            args '--user $(id -u):$(id -g)'
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
