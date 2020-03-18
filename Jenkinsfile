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
                    sh 'make all'
             }
         }
         stage('Test') {
             steps {
                    echo "make test"
//                     sh 'make test'
             }
         }
         stage('Deploy') {
             steps {
                 echo "make publish"
//                  sh 'make publish'
             }
         }
     }

 }