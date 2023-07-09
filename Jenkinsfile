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

        stage('Build and push to ECR') {
            steps {
                withCredentials([
                    aws(
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        script {
                        def region = "us-east-1"
                        def repo_name="my-app"
                        def tag="latest"
                        def repo_uri = "499632135972.dkr.ecr.us-east-1.amazonaws.com/${repo_name}"

                        sh 'cd visitors_count'
                        sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${repo_uri}"
                        sh 'docker build --no-cache -t my-app ./visitors_count'
                        sh 'docker tag my-app:latest 499632135972.dkr.ecr.us-east-1.amazonaws.com/my-app:latest'
                        sh "docker push ${repo_uri}:$tag"
                        }
                    }
            }
        }

    }
}