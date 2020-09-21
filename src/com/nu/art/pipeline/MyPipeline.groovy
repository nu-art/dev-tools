package com.nu.art.pipeline

class MyPipeline
  implements Serializable {

  def script
  Integer timeout = 300000 // 5 min
  GitRepo repo
  Docker docker

  MyPipeline(script) {
    this.script = script
  }

  String buildCommand(String command, LinkedHashMap<String, String> params) {
    List<String> _params = params.collect { key, value -> "--${key}=${this.script.env[value]}".toString() }
    String paramsAsString = ""
    for (i in 0..<_params.size()) {
      paramsAsString += " ${_params.get(i)}"
    }
    logInfo("paramsAsString: ${paramsAsString}")
    return "${command} ${paramsAsString}"
  }

  void setTimeout(Integer timeout) {
    this.timeout = timeout
  }

  String getEnv(String key) {
    return script.env[key]
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

  void cd(String folder, Closure todo) {
    script.dir(folder) {
      todo.call()
    }
  }

  Docker createDocker(String key, String version) {
    this.docker = new Docker(this, key, version)
    this.docker.init()
    this.docker.addVirtualFile("${script.env.WORKSPACE}")
    this.docker.addEnvironmentVariable(Docker.EnvVar_Workspace, "${script.pwd()}".toString())
    this.docker.addEnvironmentVariable("BUILD_NUMBER", "${script.env.BUILD_NUMBER}".toString())

    return this.docker
  }

  GitRepo createGitRepo(String url) {
    this.repo = new GitRepo(this, url)
    return this.repo
  }

  void logVerbose(GString message) {
    logVerbose message.toString()
  }

  void logVerbose(String message) {
    script.echo message
  }

  void logDebug(GString message) {
    logDebug message.toString()
  }

  void logDebug(String message) {
    script.echo message.toString()
  }

  void logInfo(GString message) {
    logInfo message.toString()
  }

  void logInfo(String message) {
    script.echo "### ${message}"
  }

  void logError(GString message) {
    logError message.toString()
  }

  void logError(String message) {
    script.echo " ---------------- ###### ------------------- \n${message}"
  }

  MyPipeline sh(GString command) {
    return sh(command.toString())
  }

  MyPipeline sh(String command) {
    script.sh "${command}"
    return this
  }
}
