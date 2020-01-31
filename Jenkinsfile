// library is loaded from github.com/wkda/jenkins-libraries-devops
@Library('devops@v0.0.2') _

pipeline {

    agent {
        node {
            label "docker-builder"
        }
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        ansiColor("xterm")
        timeout(time: 1, unit: "HOURS")
        buildDiscarder(logRotator(numToKeepStr: "30"))
    }

    environment {
        // return the 7 characters from the builds
        SHORT_COMMIT = "${env.GIT_COMMIT.trim().take(7)}"
    }

    /**
     * Define jenkins pipeline parameter for the builds.
     *
     * Please note the parameters only appears on the jenkins after the first run of a branch
     * or a tag. The reason is due to jenkins pipeline implementation, where the Jenkinsfile is
     * only loaded during the build, therefore the parameter will be only defined after the first
     * build.
     */
    parameters {
        choice name: 'ENVIRONMENT', choices: ["qa-1", "qa-2", "prod"],
            description: "Define which environment to deploy. This parameter is ignored on Production build"
    }

    // Pipeline steps starts here.
    stages {

        /**
         * Steps responsible to setup environment dynamic environment variables and read config
         * from specs.json file.
         */
        stage("Setup") {
            steps {
                script {
                    def project = readYaml file: 'descriptor.yml'  /* read properties such as project and team names */

                    // export specs.json file to an environment variables
                    env.TEAM             = project["team"]
                    env.PROJECT          = project["name"]
                    env.TEAM_EMAIL       = project["team_email"]
                    env.BUCKET_NAME      = project["lambda_bucket"]
                    env.TERRAFORM_BUCKET = project["terraform_bucket"]

                    // define lambda package path on S3 bucket repository
                    env.BUCKET_PATH    = "${env.TEAM}/${env.PROJECT}/${env.PROJECT}-${env.SHORT_COMMIT}.zip"
                    env.BUCKET_TAGPATH = "${env.TEAM}/${env.PROJECT}/${env.PROJECT}-${env.TAG_NAME}.zip"

                    // loading variables mapping to terraform variables
                    env.TF_VAR_team      = "${env.TEAM}"
                    env.TF_VAR_project   = "${env.PROJECT}"
                    env.TF_VAR_lambda_s3_bucket = "${env.BUCKET_NAME}"
                    env.TF_VAR_lambda_s3_path   = (env.TAG_NAME || env.GIT_TAG) ? "${env.BUCKET_TAGPATH}" : "${env.BUCKET_PATH}"

                    // fallback to QA when the vars is not set, happens on the first pipeline build
                    env.DEPLOY_ENVIRONMENT = (env.BUILD_ENVIRONMENT) ? "${env.BUILD_ENVIRONMENT}" : "${env.ENVIRONMENT}" 

                    if (env.DEPLOY_ENVIRONMENT == null || env.DEPLOY_ENVIRONMENT == "null")
                        env.DEPLOY_ENVIRONMENT = "qa-1"
                }
            }
        }

        /**
         * Validate commits message, which only happens on branch other than master.
         */
        stage('Validate commits') {
            when { not { branch 'master' } }
            steps {
                validateCommits() // loaded  from shared library
            }
        }

        /**
         * Stage to perform test on the code before building the lambda package
         */
//         stage("Test") {
//             when {
//                 not { environment name: 'DEPLOY_ENVIRONMENT', value: 'prod' }
//             }
//
//             steps {
//                 sh "make test"
//             }
//         }

        /**
         * Stage to download and build lambda project. This stage should be skipped
         * on production build
         */
        stage("Build") {
            when {
                not { environment name: 'DEPLOY_ENVIRONMENT', value: 'prod' }
            }

            steps {
                sh "make build"
            }
        }

        /**
         * Execute terraform plan for only (without applying)
         */
        stage("Deploy Plan") {
            steps {
                dir("./terraform") {

                    // applying terraform code
                    sh """
                        terraform init -force-copy \
                            -backend-config "bucket=${env.TERRAFORM_BUCKET}" \
                            -backend-config "key=apps/${env.TEAM}/${env.PROJECT}"

                        terraform workspace select ${env.DEPLOY_ENVIRONMENT} || terraform workspace new ${env.DEPLOY_ENVIRONMENT}

                        terraform plan -var-file=vars/${env.DEPLOY_ENVIRONMENT}.tfvars -out=apply.tfplan | \
                    """
                }
            }
        }

        /**
         * Deploy to QA should only be triggered when the master branch
         * is being built or when a new tag is released
         */
        stage("Deploy Apply") {
            when {
                anyOf {
                    branch "master"   // build if branch is master
                    buildingTag()     // build when a tag is built

                    // run this state when the BUILD_ENVIRONMENT var is set to prod
                    environment name: 'BUILD_ENVIRONMENT', value: 'prod'

                    // it's very likely your project won't need the following config
                    branch "python"   // for python example
                }
            }

            steps {
                dir("./terraform") {
                    sh "terraform apply apply.tfplan"
                }
            }
        }
    }

    // Define any post build actions for failure or succed builds
    post {

        // steps to do when the build finishes succesfully.
        success {
            setBuildStatus("Build succeeded", "SUCCESS") // load from shared library
        }

        // steps to do when the build fails
        failure {

            setBuildStatus("Build failed", "FAILURE") // loaded from share library

            // send an email when build fails to the respective team and developrs fetched
            // from GIT CHANGELOG users.
            emailext attachLog: true,
                subject: "Jenkins build failed: ${env.JOB_URL}",
                recipientProviders: ["${env.TEAM_EMAIL}"],
                body: "Jenkins build: ${env.BUILD_URL} failed. Please check logs attached"
        }
    }
}
