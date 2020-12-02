package com.nu.art.pipeline.modules.docker

import com.nu.art.pipeline.workflow.variables.VarConsts

class DockerConfig {
	final DockerModule module
	final String key
	final String version

	def envVariables = [:]
	def virtualFiles = [:]

	DockerConfig(DockerModule module, String key, String version) {
		this.module = module
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
		addEnvironmentVariable(VarConsts.Var_Workspace.varName, "${VarConsts.Var_Workspace.get()}".toString())
		addEnvironmentVariable(VarConsts.Var_BuildNumber.varName, "${VarConsts.Var_BuildNumber.get()}".toString())

		addVirtualFile(VarConsts.Var_Workspace.get())
		addVirtualFile("/home/jenkins/.config")
		addVirtualFile("/home/jenkins/.ssh/id_rsa")
		addVirtualFile("/home/jenkins/.ssh/known_hosts")

		return new Docker(module, this).init()
	}
}
