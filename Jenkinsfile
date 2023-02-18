pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = "us-east-1"
    }
    stages {
        stage("Create an EKS Cluster") {
            steps {
                script {
                    dir('Terraform') {
                        sh "terraform init"
                        sh "terraform apply -auto-approve"
                    }
                }
            }
        }
        stage('Push to AWS ECR') {
            steps {
                    sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 811286130539.dkr.ecr.us-east-1.amazonaws.com'
                    sh 'docker build -t maxrepo .'
                    sh 'docker tag maxrepo:latest 811286130539.dkr.ecr.us-east-1.amazonaws.com/maxrepo:latest'
                    sh 'docker push 811286130539.dkr.ecr.us-east-1.amazonaws.com/maxrepo:latest'
                }
            }
        }    
        stage("Deploy to EKS") {
            steps {
                script {
                    dir('kubernetes') {
                        sh "aws eks update-kubeconfig --name max_prod_cluster"
                        sh "kubectl apply -f deployment.yaml"
                        sh "kubectl apply -f service.yaml"

                    }
                }
            }
        }
    }
}