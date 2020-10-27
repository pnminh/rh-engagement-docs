def repoUrl='https://github.com/test-job2'
pipelineJob("job2") {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name('origin')
                        url(repoUrl)
                        credentials('user-pass-key')
                        refspec('+refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*')
                        branch('${sha1}')
                    }
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
    configure {
        it / definition / lightweight(false)
        // from my testing only https endpoint works with github pull request plugin
        it / 'properties' / 'com.coravy.hudson.plugins.github.GithubProjectProperty' {
            projectUrl(repoUrl)
        }
    }
    triggers {
        githubPullRequest {
            orgWhitelist('RedHat')
            cron('H/5 * * * *')
            useGitHubHooks()
        }
    }
}
