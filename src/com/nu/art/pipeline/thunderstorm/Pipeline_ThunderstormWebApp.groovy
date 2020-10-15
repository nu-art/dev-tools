package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.workflow.WorkflowModule

class Pipeline_ThunderstormWebApp<T extends Pipeline_ThunderstormWebApp>
	extends Pipeline_ThunderstormCore<T> {

	protected String env
	protected String fallEnv

	Pipeline_ThunderstormWebApp(GString name, Class<? extends WorkflowModule>... modules = []) {
		this(name.toString(), modules)
	}

	Pipeline_ThunderstormWebApp(String name, Class<? extends WorkflowModule>... modules = []) {
		super(name, modules)
	}

	Pipeline_ThunderstormWebApp(Class<? extends WorkflowModule>... modules = []) {
		super(modules)
	}

	protected void setEnv(String env, String fallEnv = "") {
		this.env = env
		this.fallEnv = fallEnv
	}

	protected void deploy() {
		addStage("deploy", { this._deploy() })
	}

	protected void _install() {
		_sh("bash build-and-install.sh --set-env=${this.env} -fe=${this.fallEnv} --install --no-build --link")
	}

	void _deploy() {
		_sh("bash build-and-install.sh --deploy --quick-deploy --no-git")
	}

	@Override
	void pipeline() {}
}
