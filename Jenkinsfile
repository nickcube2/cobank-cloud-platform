pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    CLUSTER_NAME = "cobank-eks"
    APP_NAMESPACE = "cobank"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Deploy Platform') {
      steps {
        sh '''
          ansible-playbook ansible/main.yml \
            -i ansible/inventory/localhost.yml
        '''
      }
    }
  }
}
