package com.nu.art.pipeline.thunderstorm


import com.nu.art.pipeline.modules.build.BuildModule
import com.nu.art.pipeline.modules.docker.Docker
import com.nu.art.pipeline.modules.docker.DockerModule
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.modules.git.GitRepo
import com.nu.art.pipeline.thunderstorm.models.VersionApp
import com.nu.art.pipeline.workflow.BasePipeline
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.utils.Utils
import com.nu.art.pipeline.workflow.variables.VarConsts

abstract class Pipeline_ThunderstormCore<T extends Pipeline_ThunderstormCore>
	extends BasePipeline<T> {

	protected Docker docker
	protected GitRepo repo

	Pipeline_ThunderstormCore(Class<? extends WorkflowModule>... modules) {
		this(null, modules)
	}

	Pipeline_ThunderstormCore(String name, Class<? extends WorkflowModule>... modules) {
		super(name, (([DockerModule.class, GitModule.class] as Class<? extends WorkflowModule>[]) + modules))
	}

	@Override
	protected void init() {

	}

	T setDocker(Docker docker) {
		this.docker = docker
		return (T) this
	}

	T setRepo(GitRepo repo) {
		this.repo = repo
		return (T) this
	}

	GitRepo getRepo() {
		return repo
	}

	T checkout(Closure postCheckout) {
		if (repo) addStage("checkout", {
			getRepo().cloneRepo()
			getRepo().cloneSCM()
			if (postCheckout) postCheckout()
		})
		if (docker) addStage("launch-docker", { docker.launch() })
		return (T) this
	}

	T install() {
		addStage("install", { this._install() })
		return (T) this
	}

	T clean() {
		addStage("clean", { this._clean() })
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
		_sh("bash build-and-install.sh --install --no-build --link --debug")
	}

	protected void _clean() {
		_sh("bash build-and-install.sh --clean --no-build --link --debug")
	}

	protected void _compile() {
		_sh("bash build-and-install.sh --debug")
	}

	protected void _lint() {
		_sh("bash build-and-install.sh --lint --no-build --debug")
	}

	protected void _test() {
		_sh("bash build-and-install.sh --test --no-build  --debug")
	}

	String _sh(GString command, readOutput = false) {
		return _sh(command.toString(), readOutput)
	}

	String _sh(String command, readOutput = false) {
		if (docker) return docker.sh(command, "${VarConsts.Var_Workspace.get()}/${repo.getOutputFolder()}")

		return repo.sh(command, readOutput)
	}

	protected String getVersion(String path) {
		if (!path) path = "${repo.getOutputFolder()}/version-app.json"
		String pathToFile = getModule(BuildModule.class).pathToFile(path)
		if (!workflow.fileExists(pathToFile)) return null

		String fileContent = workflow.readFile(pathToFile)
		VersionApp versionApp = Utils.parseJson(fileContent) as VersionApp
		return versionApp.version
	}

	void setDisplayName() {
		def version = getVersion() ? " - v${getVersion()}" : ""
		def branch = ""
		if (repo) branch = " - ${repo.getBranch()}"
		getModule(BuildModule.class).setDisplayName("#${VarConsts.Var_BuildNumber.get()}: ${getName()}${branch}${version}")
	}

	@Override
	void cleanup() {
		if (docker) docker.kill()

		_sh("bash build-and-install.sh --clean-env --debug")
		super.cleanup()
	}
}