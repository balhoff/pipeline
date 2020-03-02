pipeline {
     agent {
         dockerfile {
             filename 'Dockerfile'
             label 'zeppo'
         }
     }
     stages {
         stage('Build') {
             steps {
                 'make all'
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