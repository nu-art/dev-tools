package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.exceptions.BadImplementationException
import com.nu.art.pipeline.modules.BuildModule
import com.nu.art.pipeline.modules.docker.Docker
import com.nu.art.pipeline.modules.docker.DockerModule
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.modules.git.GitRepo
import com.nu.art.pipeline.thunderstorm.models.VersionApp
import com.nu.art.pipeline.workflow.NewBasePipeline
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.utils.Utils
import com.nu.art.pipeline.workflow.variables.VarConsts

abstract class Pipeline_ThunderstormCore<T extends Pipeline_ThunderstormCore>
	extends NewBasePipeline<T> {

	protected GitRepo repo
	protected Docker docker

	Pipeline_ThunderstormCore(Class<? extends WorkflowModule>... modules) {
		this(null, modules)
	}

	Pipeline_ThunderstormCore(String name, Class<? extends WorkflowModule>... modules) {
		super(name, (([DockerModule.class, GitModule.class] as Class<? extends WorkflowModule>[]) + modules))
	}

	T setDocker(Docker docker) {
		this.docker = docker
		return (T) this
	}

	T setRepo(GitRepo repo) {
		this.repo = repo
		return (T) this
	}

	T checkout(Closure postCheckout) {
		if (repo)
			addStage("checkout", {
				repo.cloneRepo()
				if(postCheckout)
					postCheckout()
			})
		if (docker)
			addStage("launch-docker", { docker.launch() })
		return (T) this
	}

	T install() {
		addStage("install", { this._install() })
		return (T) this
	}

	T build() {
		addStage("compile", { this._compile() })
		addStage("lint", { this._lint() })
		return (T) this
	}

	T test() {
		addStage("test", { this._test() })
		return (T) this
	}

	T run(String name, Closure toRun) {
		addStage(name, { toRun() })
		return (T) this
	}

	protected void _install() {
		_sh("bash build-and-install.sh --install --no-build --link")
	}

	protected void _compile() {
		_sh("bash build-and-install.sh")
	}

	protected void _lint() {
		_sh("bash build-and-install.sh --lint --no-build")
	}

	protected void _test() {
		_sh("bash build-and-install.sh --test --no-build")
	}

	T _sh(GString command) {
		return _sh(command.toString())
	}

	T _sh(String command) {
		if (docker) {
			docker.sh(command)
			return (T) this
		}

		return (T) workflow.sh(command)
	}


	String readFile(String pathToFolder, String file) {
		String pathToFile = "${VarConsts.Var_Workspace.get()}/${pathToFolder}/${file}"
		if (!workflow.script.fileExists(pathToFile))
			throw new BadImplementationException("Could not find file: ${pathToFile}")

		logDebug("Reading file: ${pathToFile}")
		return workflow.script.readFile(pathToFile)
	}

	protected String getVersion() {
		String fileContent = readFile(repo.getOutputFolder(), "version-app.json")
		VersionApp versionApp = Utils.parseJson(fileContent) as VersionApp
		return versionApp.version
	}

	protected setDefaultDisplayName() {
		getModule(BuildModule.class).setDisplayName("#${VarConsts.Var_BuildNumber.get()} - ${repo.getBranch()} - v${getVersion()}")
	}
}