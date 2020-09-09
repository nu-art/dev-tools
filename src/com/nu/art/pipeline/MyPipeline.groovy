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

  addStage(String label, Closure stageMethod) {
    script.stage(label, () -> {
      try {
        stageMethod()
      } catch (e) {
        logInfo(e.getMessage())
        e.printStackTrace()
      } finally {
        this.docker.kill()

      }
    })
  }

  Docker createDocker(String key, String version) {
    this.docker = new Docker(this, key, version)
    this.docker.init()
    this.docker.addVirtualFile("${script.env.WORKSPACE}")
    this.docker.addEnvironmentVariable("BUILD_NUMBER", "${script.env.BUILD_NUMBER}".toString())

    return this.docker
  }

  void setGitRepo(GitRepo repo) {
    this.repo = repo
  }

  public void logInfo(GString message) {
    logInfo message.toString()
  }

  public void logInfo(String message) {
    script.echo message
  }

  public void sh(GString command) {
    logInfo(command)
    script.sh command
  }

  void runEnvDocker() {
    def currDir = script.pwd()
    containerName = "ci_gf_${script.env.JOB_NAME}_${script.env.BUILD_NUMBER}".replaceAll("/", "-")
  }
}
