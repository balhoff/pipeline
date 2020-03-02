pipeline {
    agent any
     stages {
         stage('Build') {
             agent {
                      dockerfile {
                          filename 'Dockerfile'
                          label 'zeppo'
                       }
              }
             steps {
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