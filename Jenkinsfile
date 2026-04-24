pipeline {
  agent any
  stages {
    stage('Checkout') {
      steps {
        echo 'Código obtido do GitHub!'
      }
    }
    stage('Testes') {
      steps {
        sh 'cd /home/ubuntu/devops-project && bash test.sh'
      }
    }
    stage('Build Image') {
      steps {
        sh 'cd /home/ubuntu/devops-project && docker build -t devops-app:latest .'
      }
    }
    stage('Import para K3s') {
      steps {
        sh 'docker save devops-app:latest | k3s ctr images import -'
      }
    }
    stage('Deploy no K3s') {
      steps {
        sh 'kubectl apply -f /home/ubuntu/devops-project/k8s/'
      }
    }
  }
  post {
    success {
      echo 'Deploy realizado com sucesso! ✅'
    }
    failure {
      echo 'Pipeline falhou! Deploy cancelado. ❌'
    }
  }
}
