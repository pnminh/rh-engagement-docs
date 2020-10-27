import javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration
import jenkins.model.GlobalConfiguration
import java.util.logging.Level
import java.util.logging.Logger

final def LOG = Logger.getLogger("InitScripts")

// disable Job DSL script approval
LOG.log(Level.INFO, 'Disabling Job DSL script approval')
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).useScriptSecurity=false
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).save()
LOG.log(Level.INFO, 'Done disabling Job DSL script approval')