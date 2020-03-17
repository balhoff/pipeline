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

                    echo "test print ss "
                    pwd
                     make all
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