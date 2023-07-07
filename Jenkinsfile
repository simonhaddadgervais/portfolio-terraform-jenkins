pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh '''
                cd visitors_count
                pip install -r requirements.txt
                python3 -m pytest'''
                }
            }

        stage('Terraform') {
            steps {
                withCredentials([
                    aws(
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                        terraform init
                        terraform apply -auto-approve
                        '''
                    }
            }
        }
    }
}