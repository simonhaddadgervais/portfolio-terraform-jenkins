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
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                        '''
                    }
            }
        }

        stage('update S3') {
            steps {
                withCredentials([
                    aws(
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws s3 sync ./resume-site s3://simonresume"
                    }
            }
        }
    }
}