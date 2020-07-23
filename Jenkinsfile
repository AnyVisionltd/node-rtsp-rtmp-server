pipeline {
    agent { 
        label 'cicd'
    }
    options {
        timestamps()
        disableConcurrentBuilds()
        ansiColor('xterm')
        timeout(time: 3, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr:'50'))        
    }    
    libraries {
        lib('pipeline-library')
    }
    environment {
        SHORT_COMMIT = "${GIT_COMMIT[0..6]}"
        HELM_CATALOG_CRED = credentials('helm_catalog_services')
        HELM_CHART_NAME = 'rtstreamer'
    }
    stages {
        stage('Initialize') {     
            steps {
                script {
                    genericPipelineNodejs()
                }
            }
        }
    }
}
