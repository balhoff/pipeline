pipeline {
    agent {
//         dockerfile {
//           filename 'Dockerfile'
//           label 'zeppo'
//           args '-u root:root'
//         }
            docker {
                    image 'obolibrary/odkfull:v1.2.22'
                    // Reset Jenkins Docker agent default to original
                    // root.
                    args '-u root:root'
            }
    }
     stages {
         stage('Build') {
             steps {
                 sh 'make all'
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