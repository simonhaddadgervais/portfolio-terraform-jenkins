pipeline {
    agent any

    environment {
    account = "499632135972"
    region = "us-east-1"
    repo_name = "my-app"
    tag = "latest"
    repo_uri = "${account}.dkr.ecr.us-east-1.amazonaws.com/${repo_name}"
    }

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