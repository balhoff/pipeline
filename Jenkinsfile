pipeline {
    agent {
        dockerfile  true

//           filename 'Dockerfile'
//           label 'zeppo'
//           args '-u root:root'
//         }
    }
     stages {
         stage('Build') {
             steps {

                    echo "test print ss "
                    sh 'make all'
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