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
//                  sh 'make all'
                    echo "test print ss "
             }
         }
         stage('Test') {
             steps {
//                  sh 'make test'
                    echo "test print ss 2"
             }
         }
         stage('Deploy') {
             steps {
                 sh 'make publish'
             }
         }
     }

 }