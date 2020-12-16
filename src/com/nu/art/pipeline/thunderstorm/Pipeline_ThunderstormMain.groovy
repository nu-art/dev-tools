package com.nu.art.pipeline.thunderstorm


import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Var_Env

class Pipeline_ThunderstormMain<T extends Pipeline_ThunderstormMain>
	extends Pipeline_ThunderstormWebProject<T> {

	public Var_Env NO_GIT = new Var_Env("NO_GIT")


	Pipeline_ThunderstormMain(String name, String slackChannel, Class<? extends WorkflowModule>... modules) {
		super(name, slackChannel, modules)
	}

	void declareEnv(String env, String projectId) {
		envProjects.put(env, projectId)
	}

	@Override
	void pipeline() {
		super.pipeline()
		publish()
	}

	protected T publish() {
		addStage("publish", { this._publish() })
		return this as T
	}

	void _publish() {
		_sh("bash build-and-install.sh --publish ${NO_GIT.get() == "true" ? "--no-git" : ""}")
	}
}
