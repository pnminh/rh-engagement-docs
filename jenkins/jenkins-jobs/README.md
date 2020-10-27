# Set up Jenkins jobs
## Set up Jenkins jobs with a seed job using Jenkinsfile
### Disable Job DSL script approval   
By default  Job DSL scripts are blocked by Jenkins. The segment discusses method to unblock that.   

Option 1: Uncheck Enable script security for Job DSL scripts in the CSRF Protection section of the "Configure Global Security"   
Option 2: Run init script file (included at `utils/jenkins-init-scripts/disable-job-dsl-script-approval.groovy`): 
```
import javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration
import jenkins.model.GlobalConfiguration

// disable Job DSL script approval
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).useScriptSecurity=false
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).save()
```
For Jenkins on Openshift/Kubernetes, we can create this file using the config map and then set it as a volume with `subPath` option:
```
$ oc create configmap disable-job-dsl-script-approval --from-file=utils/jenkins-init-scripts/disable-job-dsl-script-approval.groovy 
$ oc set volumes dc/jenkins --type=configmap --add --overwrite --configmap-name=disable-job-dsl-script-approval --sub-path=disable-job-dsl-script-approval.groovy --mount-path=/var/lib/jenkins/init.groovy.d/disable-job-dsl-script-approval.groovy --name disable-job-dsl-script-approval
```
Option 3: Use Permissive Script Security Plugin
### References:
- https://stackoverflow.com/questions/43699190/seed-job-asks-for-script-approval-in-jenkins
- https://stackoverflow.com/questions/45416961/jenkins-in-process-script-approval
- https://plugins.jenkins.io/permissive-script-security/
## Convert Jenkins jobs to Job DSL
- Look for `${JOB_NAME}/config.xml` file in `$JENKINS_HOME/jobs` folder.
- Job DSL uses `/` character to represent the node from the `config.xml`
- An example of the job `config.xml` file content are provided at `utils/xml-jobs/job1-config.xml` and `xml-jobs/job2-config.xml` which can be converted to the 2 groovy jobs `jobs/job1.groovy` and `jobs/job2.groovy`