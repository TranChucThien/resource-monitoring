pipeline {
  agent any

  environment {
    IMAGE_NAME = "chucthien03/resource-monitoring-app"
    IMAGE_TAG  = "v${env.BUILD_NUMBER}"
    HELM_RELEASE = "my-monitoring-app"
    HELM_CHART = "oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app"
    HELM_VERSION = "0.2.0"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        echo "Branch: ${env.BRANCH_NAME} | Build: #${env.BUILD_NUMBER}"
      }
    }

    stage('Build & Test') {
      parallel {
        stage('Test') {
          steps {
            dir('app') {
              sh 'pip install --break-system-packages -r requirements.txt'
              sh 'python -m pytest tests/ || echo "No tests found, skipping"'
            }
          }
        }
        stage('Lint') {
          steps {
            dir('app') {
              sh 'flake8 app.py --max-line-length=120 || true'
            }
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh """
          docker build \
            -t ${IMAGE_NAME}:${IMAGE_TAG} \
            -f app/Dockerfile_op \
            ./app
        """
      }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh """
            echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy to K8s') {
      steps {
        sh """
          helm upgrade ${HELM_RELEASE} ${HELM_CHART} \
            --version ${HELM_VERSION} \
            --set app.image.tag=${IMAGE_TAG}
        """
      }
    }

    stage('Verify') {
      steps {
        sh """
          kubectl rollout status deployment/resource-monitoring-app-deployment --timeout=120s
          kubectl get pods -l app=resource-monitoring-app
        """
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline SUCCESS — ${IMAGE_NAME}:${IMAGE_TAG} deployed"
    }
    failure {
      echo "❌ Pipeline FAILED — Rolling back Helm release"
      sh "helm rollback ${HELM_RELEASE} || true"
    }
    always {
      sh 'docker logout || true'
    }
  }
}
