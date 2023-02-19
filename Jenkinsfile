pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = "us-east-1"
        ECR_REPOSITORY = 'maxrepo'
        IMAGE_TAG = 'latest'
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

        stage('Build Docker image') {
            steps {
                script {
                  sh "sudo docker build -t maxrepo ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Log in to ECR
                    withCredentials([string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'), string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                    }
                    // Tag the Docker image and push it to ECR
                    sh "docker tag my-docker-image ${ECR_REPOSITORY}:latest"
                    sh "docker push ${ECR_REPOSITORY}:latest"
                        }
                    }
                }
            }
        }

        stage("Deploy to EKS") {
            steps {
                script {
                    dir('kubernetes') {
                        sh "aws eks update-kubeconfig --name myapp-eks-cluster"
                        sh "kubectl apply -f nginx-deployment.yaml"
                        sh "kubectl apply -f nginx-service.yaml"
                    }
                }
            }
        }
    }
}
