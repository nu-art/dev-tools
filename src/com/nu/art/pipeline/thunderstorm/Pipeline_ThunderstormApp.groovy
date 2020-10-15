package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.workflow.WorkflowModule

class Pipeline_ThunderstormApp<T extends Pipeline_ThunderstormApp>
	extends Pipeline_ThunderstormCore<T> {

	Pipeline_ThunderstormApp(GString name, Class<? extends WorkflowModule>... modules = []) {
		this(name.toString(), modules)
	}

	Pipeline_ThunderstormApp(String name, Class<? extends WorkflowModule>... modules = []) {
		super(name, modules)
	}

	Pipeline_ThunderstormApp(Class<? extends WorkflowModule>... modules = []) {
		super(modules)
	}

	void preparePipeline() {
		checkout()
		install()
	}

	void pipeline() {
		preparePipeline()
	}
}