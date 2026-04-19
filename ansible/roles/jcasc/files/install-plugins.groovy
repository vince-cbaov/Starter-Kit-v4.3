import jenkins.model.*
import hudson.model.UpdateCenter

def plugins = [
  "configuration-as-code",
  "git",
  "github",
  "credentials",
  "credentials-binding",
  "docker-workflow",
  "kubernetes",
  "azure-cli",
  "azure-credentials",
  "azure-keyvault"
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
