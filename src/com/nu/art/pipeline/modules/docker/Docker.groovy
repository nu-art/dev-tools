package com.nu.art.pipeline.modules.docker

import com.nu.art.pipeline.IShell
import com.nu.art.pipeline.exceptions.BadImplementationException
import com.nu.art.pipeline.workflow.variables.VarConsts

class Docker
	implements IShell<Docker>, Serializable {

	final String id = UUID.randomUUID().toString()
	final DockerConfig config
	final DockerModule module

	Docker(DockerModule module, DockerConfig config) {
		this.config = config
		this.module = module
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
		module.logInfo("Launching docker: ${id}")
		module.workflow.sh """docker run --rm -d --net=host --name ${id}${VarConsts.Var_JobName.get()}-${VarConsts.Var_BuildNumber.get()} ${envVars} ${virtualFilesVars} ${dockerLink} tail -f /dev/null"""
		return this
	}

	Docker sh(GString command, GString workingDirector = "${VarConsts.Var_Workspace.get()}") {
		if (!command)
			throw new BadImplementationException("Trying to execute a command that is undefined")

		return sh(command.toString(), workingDirector.toString())
	}

	Docker sh(String command, String workingDirector = VarConsts.Var_Workspace.get()) {
		if (!command)
			throw new BadImplementationException("Trying to execute a command that is undefined")

		module.workflow.sh """docker exec -w ${workingDirector} ${id} bash -c \"${command}\""""
		return this
	}

	void kill() {
		module.workflow.logInfo("Killing docker: ${id}")
		module.workflow.sh "docker rm -f ${id}"
	}
}
