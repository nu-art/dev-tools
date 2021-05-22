package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.modules.SlackModule
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Var_Env

class Pipeline_ThunderstormMain<T extends Pipeline_ThunderstormMain>
	extends Pipeline_ThunderstormWebProject<T> {

	public Var_Env NO_GIT = new Var_Env("NO_GIT")


	Pipeline_ThunderstormMain(String name, String slackChannel, Class<? extends WorkflowModule>... modules) {
		super(name, slackChannel, modules)
	}

	protected T publish() {
		addStage("publish", { this._publish() })
		return this as T
	}

	void _publish() {
		_sh("bash build-and-install.sh --publish --quick-publish --debug ${NO_GIT.get() == "true" ? "--no-git" : ""}")
	}

	@Override
	void cleanup() {
	}

	@Override
	void pipeline() {
		checkout({
			getModule(SlackModule.class).setOnSuccess(getRepo().getChangeLog().toSlackMessage())
		})

		install()
		clean()
		build()
//		test()

		publish()
		deploy()
	}
}
