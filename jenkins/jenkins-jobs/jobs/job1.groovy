// this is for master job
pipelineJob("job1") {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name('origin')
                        url('git@github.com/test-job1.git')
                        credentials('ssh-key-id')
                        branch('develop')
                    }
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
    configure {
        it / definition / lightweight(false)
        it / 'triggers' / 'com.cloudbees.jenkins.GitHubPushTrigger' / 'spec'
    }
}