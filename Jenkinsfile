pipeline {
    agent {
        label 'zeppo'
    }
    stages {
        stage('Build') {
            agent {
                docker {
                    label 'zeppo'
                    dockerfile true
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