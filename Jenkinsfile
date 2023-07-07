pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh '''
                cd visitors_count'
                pip install -r requirements.txt
                pytest'''
                }
            }
        }
    }
