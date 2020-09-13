package com.nu.art.pipeline

public class MyPipeline
  implements Serializable {

  def script
  Integer timeout = 300000 // 5 min
  GitRepo repo
  Docker docker

  MyPipeline(script) {
    this.script = script
  }

  void setTimeout(Integer timeout) {
    this.timeout = timeout
  }

  void addStage(String label, Closure stageMethod) {
    script.stage(label, {
      try {
        stageMethod()
      } catch (e) {
        this.docker.kill()
        logError(e.getMessage())
        e.printStackTrace()
        throw e
      }
    })
  }

  Docker createDocker(String key, String version) {
    this.docker = new Docker(this, key, version)
    this.docker.init()
    this.docker.addVirtualFile("${script.env.WORKSPACE}")
    this.docker.addEnvironmentVariable("WORKSPACE", "${script.pwd()}".toString())
    this.docker.addEnvironmentVariable("BUILD_NUMBER", "${script.env.BUILD_NUMBER}".toString())

    return this.docker
  }

  void setGitRepo(GitRepo repo) {
    this.repo = repo
  }

  public void logVerbose(GString message) {
    logVerbose message.toString()
  }

  public void logVerbose(String message) {
    script.echo message
  }

  public void logDebug(GString message) {
    logDebug message.toString()
  }

  public void logDebug(String message) {
    script.echo message.toString()
  }

  public void logInfo(GString message) {
    logInfo message.toString()
  }

  public void logInfo(String message) {
    script.echo "### ${message}"
  }

  public void logError(GString message) {
    logError message.toString()
  }

  public void logError(String message) {
    script.echo " ---------------- ###### ------------------- \n${message}"
  }

  public void sh(GString command) {
    script.sh "${command}"
  }
}
