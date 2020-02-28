pipeline {
    agent {
        label 'zeppo'
        dockerfile true
    }
    stages {
        stage('Build') {
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