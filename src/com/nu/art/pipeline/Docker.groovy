package com.nu.art.pipeline

import com.nu.art.exceptions

public class Docker
  implements Serializable {

  public static String EnvVar_Workspace = "WORKSPACE"
  final String key
  final String version
  final MyPipeline pipeline
  final String id = UUID.randomUUID().toString()

  def envVariables = [:]
  def virtualFiles = [:]

  Docker(MyPipeline pipeline, String key, String version) {
    this.pipeline = pipeline
    this.key = key
    this.version = version
  }

  void init() {
    addEnvironmentVariable("USER", "jenkins")
    addVirtualFile("/home/jenkins/.config")
    addVirtualFile("/home/jenkins/.ssh/id_rsa")
    addVirtualFile("/home/jenkins/.ssh/known_hosts")
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
      throw new exceptions.BadImplementationException("Trying to launch a Docker without a container key")

    if (!this.version)
      throw new exceptions.BadImplementationException("Trying to launch a Docker without a container version")

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
    pipeline.logInfo("Launching docker: ${id}")
    pipeline.sh """docker run --rm -d --net=host --name ${id} ${envVars} ${virtualFilesVars} ${dockerLink} tail -f /dev/null"""
    return this
  }

  Docker executeCommand(GString command, GString workingDirector = "${envVariables[EnvVar_Workspace]}") {
    if (!command)
      throw new exceptions.BadImplementationException("Trying to execute a command that is undefined")

    return executeCommand(command.toString(), workingDirector.toString())
  }

  Docker executeCommand(String command, String workingDirector = envVariables[EnvVar_Workspace]) {
    if (!command)
      throw new exceptions.BadImplementationException("Trying to execute a command that is undefined")

    pipeline.sh """docker exec -w ${workingDirector} ${id} bash -c \"${command}\""""
    return this
  }

  void kill() {
    pipeline.logInfo("Killing docker: ${id}")
    pipeline.sh "docker rm -f ${id}"
  }
}