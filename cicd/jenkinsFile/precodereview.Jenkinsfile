#!/usr/bin/env groovy

// def bob = "./bob/bob -r cicd/3pp-build-rulesets/ruleset2.0.yaml"
def HOST_CLUSTER = "kroto012"
def bob = "./bob/bob"

def SLAVE_NODE = null
def common_properties = "cicd/common-properties.yaml"
// def MAIL_TO='mathagi.arun@ericsson.com, somanath.jeeva@ericsson.com'
def MAIL_TO = ''
node(label: 'docker') {
    stage('Nominating build node') {
        SLAVE_NODE = "${NODE_NAME}"
        echo "Executing build on ${SLAVE_NODE}"
    }
}

pipeline {
    agent {
        node {
            label "${SLAVE_NODE}"
        }
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '50', artifactNumToKeepStr: '50'))
    }

    environment {
        // KUBECONFIG = "${WORKSPACE}/.kube/config"
        DOCKER_CONFIG_FILE = "${WORKSPACE}"
        GIT_AUTHOR_NAME = "mxecifunc"
        GIT_AUTHOR_EMAIL = "PDLMMECIMM@pdl.internal.ericsson.com"
        GIT_COMMITTER_NAME = "${USER}"
        GIT_COMMITTER_EMAIL = "${GIT_AUTHOR_EMAIL}"
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -o PubKeyAuthentication=yes"
        DOCKER_CONFIG = "${WORKSPACE}"
        FOSSA_ENABLED = "true"
        DEPENDENCY_VALIDATE_ENABLED = "true"
        MIMER_CHECK_ENABLED = "false"
        IS_VERSION_UPDATED = "false"


        // Credentials

        SELI_ARTIFACTORY_REPO = credentials('SELI_ARTIFACTORY')
        SERO_ARTIFACTORY_REPO_API_KEY=credentials ('SERO_ARM_TOKEN')
        SELI_ARTIFACTORY_REPO_API_KEY = credentials('arm-api-token-mxecifunc')
        HELM_REPO_CREDENTIALS=credentials('helm-credentials')
        CREDENTIALS_SELI_ARTIFACTORY = credentials('SELI_ARTIFACTORY')  // exposes SELI_ARTIFACTORY_REPO_USR and SELI_ARTIFACTORY_REPO_PSW
        CREDENTIALS_GERRIT=credentials('gerrit-http-password-mxecifunc')
        GERRIT_USERNAME = "${env.CREDENTIALS_GERRIT_USR}"
        GERRIT_PASSWORD = "${env.CREDENTIALS_GERRIT_PSW}"
        GERRIT_CREDENTIALS_ID = 'gerrit-http-password-mxecifunc'  // required for gerrit-review plugin

        //HELM
        HELM_DR_CHECK = "true"
        K8S_NAMESPACE = "git-repository-ci"
        HOST_CLUSTER = "${HOST_CLUSTER}"

        // Install Options
        TLS_ENABLED="true"
        SERVICE_MESH_ENABLED="true"
        NETWORK_POLICY_ENABLED="false"
        LOGSHIPPER_ENABLED="false"
        STORAGE_CLASS="rbd"

    }

    
    stages {
        stage('Commit Message Check') {
            steps {
                script {
                    def final commitMessage = new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64())
                    if (commitMessage ==~ /(?ms)((Revert)|(\[MEE\-[0-9]+\])|(\[MXE\-[0-9]+\])|(\[MXESUP\-[0-9]+\])|(\[NoJira\]))+\s\S.*/) {
                        gerritReview labels: ['Commit-Message': 1]
                    } else {
                        def final message = 'Commit message check has failed'
                        // def final link = 'https://confluence.lmera.ericsson.se/display/MXE/Code+review+WoW'
                        addWarningBadge text: message
                        addShortText text: 'malformed commit-msg',  border: 0
                        gerritReview labels: ['Commit-Message': -1], message: message 
                    }
                }
            }
        }

        stage('Submodule Init'){
            steps{
                sshagent(credentials: ['ssh-key-mxecifunc']) {
                    sh 'git clean -xdff'
                    sh 'git submodule sync'
                    sh 'git submodule update --init bob mlops-utils'
                }
            }
        }

        stage('Clean') {
            steps {
                script{
                    sh "${bob} clean"
                }
            }
        }

        stage('Init') {
            steps {
                sh "${bob} init-precodereview"
                script {
                    env.AUTHOR_NAME = sh(returnStdout: true, script: 'git show -s --pretty=%an')
                    currentBuild.displayName = currentBuild.displayName + ' / ' + env.AUTHOR_NAME
                    withCredentials([file(credentialsId: 'ARM_DOCKER_CONFIG', variable: 'DOCKER_CONFIG_FILE')]) {
                        writeFile file: 'config.json', text: readFile(DOCKER_CONFIG_FILE)
                    }
                }
            }
        }

        stage('Lint') {
            steps {
                sh "${bob} lint-test"
            }
            post {
                success {
                    gerritReview labels: ['Code-Format': 1]
                }
                unsuccessful {
                    gerritReview labels: ['Code-Format': -1]
                }
            }
        }

        stage('Image Build & Image Quality Test') {
            environment{
                ARM_API_TOKEN = credentials('arm-api-token-mxecifunc')
                SERO_ARM_TOKEN = credentials ('SERO_ARM_TOKEN')
            }
            steps {
                    sshagent(credentials: ['ssh-key-mxecifunc']) {
                        sh "${bob} build-image"
                        sh "${bob} push-image"
                    }
            }
            post {
                success {
                    gerritReview labels: ['Code-Quality': 1]
                }
                unsuccessful {
                    gerritReview labels: ['Code-Quality': -1]
                }
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: '**/image-design-rule-check-report*'
                    script{
                        sh "${bob} delete-images"
                    }
                }
            }
        }

        stage('Helm Build & Quality Test'){
            steps{
                sh "${bob} update-files"
                sh "${bob} chart-build"
                script {
                    if (HELM_DR_CHECK == "true") {
                        sh "${bob} chart-dr"
                    }
                }
            }
            post {
                unsuccessful {
                    gerritReview labels: ['Code-Quality': -1]
                }
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'build/checker-reports/**/*'
                }
            }
        }
        
        
        stage('Cluster Setup') {
            environment {
                KUBECONFIG = credentials("kubeconfig-${HOST_CLUSTER}")
                INGRESSCLASS_SYNC = "false" // This needs to be set to true for model-lcm deployment where kserve is used
                K8S_VERSION = "1.27.7"
                VCLUSTER_VERSION = "0.16.4"
            }
            steps {
                    script {
                        sh "git submodule update --remote mlops-utils" // Update mlops-utils to latest version
                        sh 'printenv | sort'
                        sh './bob/bob infra.cluster-create'
                        sh './bob/bob infra.create-cert'
                    }
                }
        }

        stage('Deploy and Validate') {
            environment {
                K8S_NAMESPACE = "${env.K8S_NAMESPACE}"
                KUBECONFIG= sh (returnStdout: true, script: 'realpath vcluster*').trim()

                // Hostnames and Cert Env variables
                GIT_REPOSITORY_HOST_NAME= sh (returnStdout: true, script: 'grep -w eric-lcm-git-repository-tls .clusterinfo|cut -d":" -f2').trim()
                GIT_REPOSITORY_TLS_SECRET_MANIFEST = sh (returnStdout: true, script: 'realpath eric-lcm-git-repository-tls.yaml').trim()
            }
            stages{
                stage('Install Service'){
                    steps{
                        sh "${bob} helm-install-precodereview"
                    }
                    post{
                        unsuccessful{
                            sh "${bob} helm-uninstall"
                        }
                    }
                }
                stage('Functional Test'){
                    steps{
                        sh 'echo test case execution'
                    }
                    post {
                        success{
                            gerritReview labels: ['System-Test': 1]
                        }
                        unsuccessful {
                            gerritReview labels: ['System-Test': -1]                            
                        }
                        always {
                            sh "./bob/bob collect-k8s-logs || true"
                            archiveArtifacts allowEmptyArchive: true, artifacts: "build/k8s-logs/*"
                            archiveArtifacts artifacts: 'test-reports/**/*.*', allowEmptyArchive: true
                            // robot outputPath: '.', logFileName: '**/log.html', outputFileName: '**/output.xml', reportFileName: '**/report.html', otherFiles:'**/*screenshot*', passThreshold: 100, unstableThreshold: 75.0
                        }
                        cleanup {
                            sh "./bob/bob helm-uninstall || true"
                        }
                    }
                }
            }
            
        }

        stage('Publish Helm Package') {
                    steps {
                        sh "${bob} helm-push-internal"
                    }
        }
        stage('Git Push Changed Files'){
            steps{
                sh "${bob} create-change"
            }
        }
        stage('FOSSA Scan'){
            when {
                expression {  env.FOSSA_ENABLED == "true" }
            }
            environment{
                FOSSA_API_KEY = credentials('FOSSA_API_KEY_PROD')
            }
            stages{                    
                stage('FOSSA Server Status Check') {
                    steps {
                        sh "${bob} 3pp.fossa-server-check"
                    }
                }

                stage('FOSSA Analyze') {
                    steps {
                        script {
                            sh "${bob} 3pp.set-image-version"
                            sh "${bob} 3pp.fossa-gitea-analyze"
                        }
                    }
                }

                stage('Fossa Scan Status Check'){
                    steps {
                        script {
                            sh "${bob} 3pp.fossa-gitea-status-check"
                        }
                    }
                }

                stage('FOSSA Report Attribution') {
                    steps {
                        script {
                            sh "${bob} 3pp.fossa-gitea-report-attribution"
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'config/fossa/**'
                }
            }
        }

        stage('FOSSA Dependency Validate') {
            when {
                expression {  env.DEPENDENCY_VALIDATE_ENABLED == "true" }
            }
            steps {
                parallel (
                        "Validate gitea dependency": { 
                            script {
                                sh "${bob} 3pp.fossa-gitea-dependency-validate"
                            }
                        },
                        "Validate 2pp dependency": { 
                            script {
                                sh "${bob} 3pp.fossa-2pp-dependency-validate"
                            }
                        },
                        "Validate 3pp dependency": { 
                            script {
                                sh "${bob} 3pp.fossa-3pp-dependency-validate"
                            }
                        }

                )
                
            }
        }

        stage('Mimer Check') {
            when {
                expression {  env.MIMER_CHECK_ENABLED == "true" }
            }
            environment{
                MUNIN_TOKEN = credentials('MUNIN_TOKEN')
            }
            steps {
                script {
                            sh "${bob} -r cicd/3pp-build-rulesets/mimer.yaml check-foss-in-mimer-gitea"
                }
            }
        }
    }
    post {
        success {
            script {
                modifyBuildDescription()
                // cleanWs()
            }
        }
        cleanup {
            script {
                sh "${bob} -r cicd/3pp-build-rulesets/build.yaml cleanup-temp-images"
            }
        }
        always {
            withCredentials([file(credentialsId: "kubeconfig-${HOST_CLUSTER}", variable: 'kubeconfig_file')]) {
                withEnv(["KUBECONFIG=${kubeconfig_file}"]) {
                    sh "${bob} infra.cluster-delete"
                    sh "${bob} infra.delete-cert"
                   
                }
            }
        }
    }
}

def modifyBuildDescription() {
    def VERSION = readFile('.bob/var.version').trim()
    def desc = "Version:${VERSION} <br>"
    desc+="Gerrit: <a href=${env.GERRIT_CHANGE_URL}>${env.GERRIT_CHANGE_URL}</a> <br>"
    currentBuild.description = desc
}

