package com.nu.art.pipeline

public class Docker
  implements Serializable {

  final String key
  final String version
  final MyPipeline pipeline
  final String id = UUID.randomUUID().toString()

  def envVariables = [:]
  def virtualFiles = [:]

  Docker(MyPipeline pipeline, String key, String version) {
    this.pipeline = pipeline;
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
    pipeline.sh """docker run --rm -d --net=host --name ${id} ${envVars} ${virtualFilesVars} ${dockerLink} tail -f /dev/null"""
    return this
  }

  Docker executeCommand(String command) {
    pipeline.sh """docker exec ${id} ./jenkins_env_entrypoint.sh "${command}" """
    return this
  }

  void kill() {
    pipeline.sh "docker rm -f ${id}"

  }
}
