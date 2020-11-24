pipeline {
    agent {
        docker {
            image 'phenoscape/pipeline-tools:v1.4'
            label 'zeppo'
        }
    }
     stages {
         stage('Build') {
             steps {
                    sh "env" 
                    sh "pwd"
                    sh "ls -AlF"
                    sh "rm -rf phenoscape-data"
                    sh "rm -rf build"
                    sh "if [ ! -d phenoscape-data ]; then git clone --depth 1 https://github.com/phenoscape/phenoscape-data.git; fi"
                    sh 'make all'
             }
         }
     }
 }
