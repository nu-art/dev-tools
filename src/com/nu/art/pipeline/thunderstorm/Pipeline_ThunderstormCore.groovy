package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.modules.docker.DockerModule
import com.nu.art.pipeline.modules.docker.DockerModule.Docker
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.modules.git.GitModule.GitRepo
import com.nu.art.pipeline.workflow.NewBasePipeline

abstract class Pipeline_ThunderstormCore<T extends Pipeline_ThunderstormCore>
	extends NewBasePipeline<T> {

	protected GitRepo repo
	protected Docker docker

	Pipeline_ThunderstormCore() {
		this(null)
	}

	Pipeline_ThunderstormCore(String name) {
		super(name, DockerModule.class, GitModule.class)
	}

	T setDocker(Docker docker) {
		this.docker = docker
		return (T) this
	}

	T setRepo(GitRepo repo) {
		this.repo = repo
		return (T) this
	}

	T checkout() {
		if (repo)
			addStage("checkout", { repo.cloneRepo() })
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
}