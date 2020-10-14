package com.nu.art.pipeline

import com.nu.art.consts.Param_EnvVar
import com.nu.art.pipeline.exceptions.BadImplementationException

class Docker
  implements IShell<Docker>, Serializable {

  final String key
  final String version
  final String id = UUID.randomUUID().toString()

  def envVariables = [:]
  def virtualFiles = [:]

  Docker(String key, String version) {
    this.key = key
    this.version = version
  }

  void init() {
  }

  Docker addEnvironmentVariable(GString key, GString value) {
    return addEnvironmentVariable(key.toString(), value.toString())
  }

  Docker addEnvironmentVariable(String key, String value) {
    envVariables[key] = value
    return this
  }

  Docker addVirtualFile(GString path) {
    return addVirtualFile(path, path)
  }

  Docker addVirtualFile(String path) {
    return addVirtualFile(path, path)
  }

  Docker addVirtualFile(GString pathFrom, GString pathTo) {
    return addVirtualFile(pathFrom.toString(), pathTo.toString())
  }

  Docker addVirtualFile(String pathFrom, String pathTo) {
    virtualFiles[pathFrom] = pathTo
    return this
  }


  Docker launch() {
    if (!this.key)
      throw new BadImplementationException("Trying to launch a Docker without a container key")

    if (!this.version)
      throw new BadImplementationException("Trying to launch a Docker without a container version")

    List<String> _envVars = envVariables.collect { key, value -> "-e ${key}=${value}".toString() }
    String envVars = ""
    for (i in 0..<_envVars.size()) {
      envVars += " ${_envVars.get(i)}"
    }

    List<String> _virtualFiles = virtualFiles.collect { key, value -> "-v ${key}:${value}".toString() }
    String virtualFilesVars = ""
    for (i in 0..<_virtualFiles.size()) {
      virtualFilesVars += " ${_virtualFiles.get(i)}"
    }

    GString dockerLink = "${this.key}:${this.version}"
    BasePipeline.instance.logInfo("Launching docker: ${id}")
    BasePipeline.instance.sh """docker run --rm -d --net=host --name ${id} ${envVars} ${virtualFilesVars} ${dockerLink} tail -f /dev/null"""
    return this
  }

  Docker sh(GString command, GString workingDirector = "${Param_EnvVar.Workspace.envValue()}") {
    if (!command)
      throw new BadImplementationException("Trying to execute a command that is undefined")

    return sh(command.toString(), workingDirector.toString())
  }

  Docker sh(String command, String workingDirector = Param_EnvVar.Workspace.envValue()) {
    if (!command)
      throw new BadImplementationException("Trying to execute a command that is undefined")

    BasePipeline.instance.sh """docker exec -w ${workingDirector} ${id} bash -c \"${command}\""""
    return this
  }

  void kill() {
    BasePipeline.instance.logInfo("Killing docker: ${id}")
    BasePipeline.instance.sh "docker rm -f ${id}"
  }
}