pipeline {
    agent {
        docker {
            image 'obolibrary/odkfull:v1.2.22'
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
                    sh 'make all'
             }
         }
         stage('Test') {
             steps {
                    echo "test print: make test"
//                     sh 'make test'
             }
         }
         stage('Deploy') {
             steps {
                 echo "test print: make publish"
//                  sh 'make publish'
             }
         }
     }

 }
