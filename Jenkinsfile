pipeline {
    agent {
        label 'agent1'
    }
    options { 
        skipDefaultCheckout() 
    }
    environment {
        DOCKER_PWD = credentials('docker-pwd')
        DEV = 'https://dev.epam.pp.ua/api'
        PROD = 'https://epam.pp.ua/api'
        REGISTRY_NAME = 'soubi8/fp'
        APP = 'api'
    }
    stages {
        stage('Clean Workspace'){
            steps {
                echo "============== Cleaning Workspace =============="
                sh 'rm -rf ./*'
            }
        }
        stage('SCM Checkout') {
            steps {
                echo "============== SCM Checkout =============="
                git branch: '${BRANCH_NAME}', credentialsId: 'jenkins_key', url: 'git@github.com:Soubi8/realworld-springboot-java.git'
            }
        }
        stage('Build API to Docker Image') {
            steps {
                echo "============== Building App to Docker Image =============="
                sh """
                    sudo usermod -aG docker $USER
                    sudo chown $USER /var/run/docker.sock
                    docker build --pull -t ${REGISTRY_NAME}:api_${BRANCH_NAME} .
                """
            }
        }
        stage('Push Docker Image') {
            steps {
                echo "============== Pushing Docker Image to DockerHub =============="
                sh 'echo "$DOCKER_PWD" | docker login -u soubi8 --password-stdin'
                sh "docker push ${REGISTRY_NAME}:api_${BRANCH_NAME}"
                sh 'docker logout' 
            }
        }
        stage('Deploy to Dev Server') {
            when {
                branch 'develop'
            }
            steps {
                echo "============== Deploying the API to Dev Server =============="
                script {
                    def dockerRun = "docker run --pull always --rm --name ${APP} -d -p 8080:8080 ${REGISTRY_NAME}:api_${BRANCH_NAME}"
                    def dockerStop = "docker stop ${APP}"
                    sshagent(['aws_fp_api']) {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${IP_DEV} '${dockerRun} || (${dockerStop} && ${dockerRun})'"
                    }
                }
            }
        }
        stage('Deploy to Prod Server') {
            when {
                branch 'master'
            }
            steps {
                echo "============== Deploying the API to Prod Server =============="
                script {
                    def dockerRun = "docker run --pull always --rm --name ${APP} -d -p 8080:8080 ${REGISTRY_NAME}:api_${BRANCH_NAME}"
                    def dockerStop = "docker stop ${APP}"
                    sshagent(['aws_fp_api']) {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${IP_PROD} '${dockerRun} || (${dockerStop} && ${dockerRun})'"
                    }
                }
            }
        }
        stage('Test the API on Dev Server') {
            when {
                branch 'develop'
            }
            steps {
                echo "============== Testing the API on Dev Server =============="
                sh """
                    bash ./200.sh ${DEV}/articles
                    export APIURL=${DEV} && bash ./doc/run-api-tests.sh
                """
            }
        }
        stage('Test the API on Prod Server') {
            when {
                branch 'master'
            }
            steps {
                echo "============== Testing the API on Prod Server =============="
                sh """
                    bash ./200.sh ${PROD}/articles
                    export APIURL=${PROD} && bash ./doc/run-api-tests.sh
                """
            }
        }
        stage('Merge Request to Master branch') {
            when {
                branch 'develop'
            }
            steps {
                echo "============== Git Merge to Master Branch =============="
                withCredentials([string(credentialsId: 'git_token', variable: 'GIT_TOKEN')]) {
                    script{
                        sh '''
                            curl \\
                                -X POST \\
                                -H \"Accept: application/vnd.github.v3+json\" \\
                                -H \"Authorization: token ${GIT_TOKEN}\" \\
                                https://api.github.com/repos/soubi8/realworld-springboot-java/merges \\
                                -d '{\"base\":\"master\",\"head\":\"develop\",\"commit_message\":\"Added Jenkinsfile, Dockerfile, test script\"}'
                        '''
                    }
                }
            }
        }
    }
}
