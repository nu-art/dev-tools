package com.nu.art.pipeline

@Grab('com.nu-art-software:nu-art-core:1.2.34')

import com.nu.art.consts.Param_CLI
import com.nu.art.consts.Param_Credentials
import com.nu.art.consts.Param_EnvVar
import com.nu.art.utils.Colors

class BasePipeline<T extends BasePipeline>
  implements IShell<T>, Serializable {

  static BasePipeline instance

  final String name
  final def script

  Integer timeout = 300000 // 5 min
  String currentStage = "IDLE"

  protected SlackNotification slack
  protected GitRepo repo
  public Docker docker

  BasePipeline(def script, String name) {
    this.script = script
    this.name = name

    instance = this
  }

  void setTimeout(Integer timeout) {
    this.timeout = timeout
  }

  void addStage(String label, Closure stageMethod) {
    script.stage(label, {
      try {
        this.currentStage = label
        logInfo("STAGE: ${this.currentStage}")
        stageMethod()
      } catch (e) {
        logError(e.getMessage())
        e.printStackTrace()
        slack.notify("Error in stage: ${label}", Colors.Red)
        this.onError(this.currentStage, e)
        throw e
      }
    })
  }

  SlackNotification slack(String channel) {
    this.slack = new SlackNotification(channel)
    return this.slack
  }

  Docker docker(String key, String version) {
    Docker docker = new Docker(key, version)
    docker.init()
    docker.addVirtualFile("${script.env.Workspace}")
    docker.addEnvironmentVariable(Param_EnvVar.Workspace.envVarName, "${script.pwd()}".toString())
    docker.addEnvironmentVariable(Param_EnvVar.BuildNumber.envVarName, "${Param_EnvVar.BuildNumber.envValue()}".toString())
    this.docker = docker
    return docker
  }

  GitRepo repo(String url, String branch = "") {
    this.repo = new GitRepo(url).setBranch(branch != "" ? branch : Param_EnvVar.BranchName.envValue()).setFolderName("")
    return this.repo
  }

  // LIFECYCLE
  T prepare(Closure _prepare) {
    addStage("started", {
      this.slack.notify("Started", Colors.Blue)
    })

    if (_prepare)
      addStage("prepare", _prepare)
  }

  T completed() {
    addStage("completed", {
      this.slack.notify("Completed", Colors.Green)
    })
  }

  protected void onError(String stage, Throwable error) {
  }

  //  LOGS
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

//  UTILS
  String getEnv(String key) {
    return script.env[key]
  }

  void cd(String folder, Closure todo) {
    script.dir(folder) {
      todo.call()
    }
  }

  void withCredentials(Param_Credentials[] params, Closure toRun) {
    script.withCredentials(params.collect { param -> param.cred() }) {
      toRun()
    }
  }

  String buildCommand(String command, Param_CLI[] params) {
    List<String> _params = params.collect { cli -> "--${cli.cliParamName}=${cli.envValue()}".toString() }
    String paramsAsString = ""
    for (i in 0..<_params.size()) {
      paramsAsString += " ${_params.get(i)}"
    }
    logInfo("paramsAsString: ${paramsAsString}")
    return "${command} ${paramsAsString}"
  }

  T sh(GString command) {
    return sh(command.toString())
  }

  T sh(String command) {
    script.sh "${command}"
    return (T) this
  }
}
