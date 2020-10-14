package com.nu.art.pipeline.modules.docker

import com.nu.art.consts.Param_EnvVar
import com.nu.art.pipeline.IShell
import com.nu.art.pipeline.exceptions.BadImplementationException
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Consts

class DockerModule
	extends WorkflowModule {

	DockerConfig create(String key, String version) {
		return new DockerConfig(key, version)
	}

	class Docker
		implements IShell<Docker>, Serializable {

		final String id = UUID.randomUUID().toString()
		final DockerConfig config

		private Docker(DockerConfig config) {
			this.config = config
		}

		void init() {
		}

		Docker launch() {
			if (!config.key)
				throw new BadImplementationException("Trying to launch a Docker without a container key")

			if (!config.version)
				throw new BadImplementationException("Trying to launch a Docker without a container version")

			List<String> _envVars = config.envVariables.collect { key, value -> "-e ${key}=${value}".toString() }
			String envVars = ""
			for (i in 0..<_envVars.size()) {
				envVars += " ${_envVars.get(i)}"
			}

			List<String> _virtualFiles = config.virtualFiles.collect { key, value -> "-v ${key}:${value}".toString() }
			String virtualFilesVars = ""
			for (i in 0..<_virtualFiles.size()) {
				virtualFilesVars += " ${_virtualFiles.get(i)}"
			}

			GString dockerLink = "${config.key}:${config.version}"
			logInfo("Launching docker: ${id}")
			workflow.sh """docker run --rm -d --net=host --name ${id} ${envVars} ${virtualFilesVars} ${dockerLink} tail -f /dev/null"""
			return this
		}

		Docker sh(GString command, GString workingDirector = "${Consts.Var_Workspace.get()}") {
			if (!command)
				throw new BadImplementationException("Trying to execute a command that is undefined")

			return sh(command.toString(), workingDirector.toString())
		}

		Docker sh(String command, String workingDirector = Consts.Var_Workspace.get()) {
			if (!command)
				throw new BadImplementationException("Trying to execute a command that is undefined")

			workflow.sh """docker exec -w ${workingDirector} ${id} bash -c \"${command}\""""
			return this
		}

		void kill() {
			workflow.logInfo("Killing docker: ${id}")
			workflow.sh "docker rm -f ${id}"
		}
	}

	class DockerConfig {
		final String key
		final String version

		def envVariables = [:]
		def virtualFiles = [:]

		DockerConfig(String key, String version) {
			this.key = key
			this.version = version
		}

		DockerConfig addEnvironmentVariable(GString key, GString value) {
			return addEnvironmentVariable(key.toString(), value.toString())
		}

		DockerConfig addEnvironmentVariable(String key, String value) {
			envVariables[key] = value
			return this
		}

		DockerConfig addVirtualFile(GString path) {
			return addVirtualFile(path, path)
		}

		DockerConfig addVirtualFile(String path) {
			return addVirtualFile(path, path)
		}

		DockerConfig addVirtualFile(GString pathFrom, GString pathTo) {
			return addVirtualFile(pathFrom.toString(), pathTo.toString())
		}

		DockerConfig addVirtualFile(String pathFrom, String pathTo) {
			virtualFiles[pathFrom] = pathTo
			return this
		}

		Docker build() {
			addEnvironmentVariable("USER", "jenkins")
			addEnvironmentVariable(Consts.Var_Workspace.varName, "${Consts.Var_Workspace.get()}".toString())
			addEnvironmentVariable(Consts.Var_BuildNumber.varName, "${Consts.Var_BuildNumber.get()}".toString())

			addVirtualFile(Consts.Var_Workspace.get())
			addVirtualFile("/home/jenkins/.config")
			addVirtualFile("/home/jenkins/.ssh/id_rsa")
			addVirtualFile("/home/jenkins/.ssh/known_hosts")

			return new Docker(this)
		}
	}
}
//+ docker exec -w /data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV 783e39a7-003b-488d-b616-24720851b5a4 bash -c bash build-and-install.sh --install --no-build --link
//+ docker exec -w /data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV@3 c45656ff-ff76-4683-9667-5bc76561f6ea bash -c bash build-and-install.sh --install --no-build --link
//
//docker run --rm -d --net=host --name c45656ff-ff76-4683-9667-5bc76561f6ea
//	-e USER=jenkins
//	-v ****:**** -v ****:****
//	-v /home/jenkins/.config:/home/jenkins/.config
//	-v /home/jenkins/.ssh/id_rsa:/home/jenkins/.ssh/id_rsa
//	-v /home/jenkins/.ssh/known_hosts:/home/jenkins/.ssh/known_hosts
//	eu.gcr.io/ir-infrastructure-246111/jenkins-ci-python-env:1.0.18 tail -f /dev/null
//
//docker run --rm -d --net=host --name 783e39a7-003b-488d-b616-24720851b5a4
//	-v ****:**** -v ****:****
//	-e WORKSPACE=/data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV
//	-e BUILD_NUMBER=46
//	-v /data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV:/data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV
//	eu.gcr.io/ir-infrastructure-246111/jenkins-ci-python-env:1.0.18 tail -f /dev/null
