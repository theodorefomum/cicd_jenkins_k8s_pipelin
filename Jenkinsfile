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
                    docker.build("maxrepo:${IMAGE_TAG}")
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'my-aws-credentials', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    script {
                        def ecr_login_cmd = sh(script: "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com", returnStdout: true).trim()
                        sh(script: ecr_login_cmd)
                        docker.withRegistry("https://${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com", 'ecr') {
                            def image = docker.image("maxrepo:${IMAGE_TAG}")
                            image.push("${ECR_REPOSITORY}:${IMAGE_TAG}")
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
