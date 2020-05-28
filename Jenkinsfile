pipeline {
    agent {
        docker {
            image 'phenoscape/pipeline-tools:v1.1'
            label 'zeppo'
        }
    }
     stages {
         stage('Build') {
             steps {
                    sh "env" 
                    sh "pwd"
                    sh "ls -AlF"
                    sh "if [ ! -d phenoscape-data ]; then git clone --depth 1 https://github.com/phenoscape/phenoscape-data.git; fi"
                    sh 'make all'
             }
         }
     }
 }
