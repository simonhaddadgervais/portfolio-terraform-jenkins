
### This project aims to create a serverless portfolio website, with AWS.

<br>
<br>

<img src="resume-site/images/INFRA.png" alt="My Image" width="700"/>

<br>
<br>

### To create this website, I used:

#### AWS resources :
- IAM
- S3
- Lambda
- APIGateway
- DynamoDB
- ACM
- Route53
- Cloudfront
- ECR

#### Programing Languages:
- Python
- Javascript

#### And
- PyCharm as IDE
- Git as VSC
- Terraform as Iac
- Linux
- Jenkins for CI/CD
- Docker to containerize the function



### CI/CD
To automate the deployment, the integration and the delivery, I implemented CI/CD, with Jenkins.

To host Jenkins I chose to use a single EC2 instance, launched by Terraform.  
I picked a t3.medium type as smaller types
were causing my instance to crash due to high CPU usage (<99%), probably caused by the Terraform stage.

I had to open ports for SSH, http and https and Jenkins port 8080.  

I SSHed into the instance and installed Jenkins, docker, terraform, aws CLI, python and pip and I added
jenkins user to docker group to allow Jenkins to use Docker.
as well I change permission for docker.sock file.  
Once all is installed and setup on the instance I can access my Jenkins webpage with the EC2 public
address with port 8080. 

For first connection I needed to retrieve the password `cat /var/jenkins_home/secrets/initialAdminPassword`

I installed aws-credentials and terraform plugins. I added my AWS credentials in the Jenkins credentials
menu, to be used in my pipeline.
I then created a pipeline, with github repo and github webhook. I used script with SCM.
I then went to my github repo settings > webhook, and added a webhook : “*publicaddress*/github-webhook/”  

Next I created a Jenkinsfile in my repository.

### The Pipeline

I already knew what stages I wanted, because I was previously using github actions for CI/CD.  

I needed :  
A test stage to test my function before deploying anything.
A terraform stage to deploy all the infrastructure
A S3 update stage to update my portfolio page.


Running the test stage was pretty straight forward, just running a single pytest command.  
For the Terraform and the S3 stage I needed permissions to access resources in AWS and this is where
the aws-credentials plugin and the Credentials menu in Jenkins came in handy.


With all of this set up, each push on my github repository is triggering Jenkins to test, build and deploy everything


*



### That's it!
