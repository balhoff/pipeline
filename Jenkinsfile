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
                    sh "if [! -d phenoscape-data]; then git clone https://github.com/phenoscape/phenoscape-data.git; fi"
                    sh "whoami"
                    sh "env" 
                    sh "groups"
                    sh "pwd"
                    sh "ls -AlF"
                    sh "rm build/mgi* build/zfin* build/hpoa*"
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
