import jenkins.model.*
import hudson.model.UpdateCenter

def plugins = [
  "configuration-as-code",
  "workflow-aggregator",
  "pipeline-stage-view",
  "git",
  "github",
  "credentials",
  "credentials-binding",
  "ssh-agent",
  "ssh-credentials",
  "docker-workflow",
  "kubernetes",
  "kubernetes-cli",
  "azure-cli",
  "azure-credentials",
  "azure-keyvault",
]

def instance = Jenkins.instance
def updateCenter = instance.updateCenter

plugins.each { plugin ->
  if (!instance.pluginManager.getPlugin(plugin)) {
    println "Installing plugin: ${plugin}"
    updateCenter.getPlugin(plugin).deploy()
  }
}

instance.save()
