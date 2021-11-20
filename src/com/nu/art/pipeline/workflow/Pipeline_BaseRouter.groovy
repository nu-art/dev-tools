package com.nu.art.pipeline.workflow


import com.nu.art.pipeline.modules.docker.Docker
import com.nu.art.pipeline.modules.docker.DockerModule
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.modules.git.GitRepo
import com.nu.art.pipeline.workflow.BasePipeline
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.VarConsts

abstract class Pipeline_BaseRouter<T extends Pipeline_BaseRouter>
	extends BasePipeline<T> {

	protected Docker docker
	protected GitRepo repo

	Pipeline_BaseRouter(Class<? extends WorkflowModule>... modules) {
		this(null, modules)
	}

	Pipeline_BaseRouter(String name, Class<? extends WorkflowModule>... modules) {
		super(name, (([DockerModule.class, GitModule.class] as Class<? extends WorkflowModule>[]) + modules))
	}

	@Override
	protected void init() {
	}

	T setRepo(GitRepo repo) {
		this.repo = repo
		return (T) this
	}

	GitRepo getRepo() {
		return repo
	}

	T checkout(Closure postCheckout) {
		if (repo)
			addStage("checkout", {
				getRepo().cloneRepo()
				getRepo().cloneSCM()
				if (postCheckout)
					postCheckout()
			})
		return (T) this
	}

	T run(String name, Closure toRun) {
		addStage(name, { toRun() })
		return (T) this
	}

	String _sh(GString command, readOutput = false) {
		return _sh(command.toString(), readOutput)
	}

	String _sh(String command, readOutput = false) {
		if (docker)
			return docker.sh(command, "${VarConsts.Var_Workspace.get()}/${repo.getOutputFolder()}")

		return repo.sh(command, readOutput)
	}

	@Override
	void cleanup() {
		if (docker)
			docker.kill()

		super.cleanup()
	}
}