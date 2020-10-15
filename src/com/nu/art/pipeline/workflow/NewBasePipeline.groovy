package com.nu.art.pipeline.workflow


import com.nu.art.core.tools.ArrayTools
import com.nu.art.pipeline.modules.BuildModule
import com.nu.art.pipeline.workflow.variables.Var_Creds

abstract class NewBasePipeline<T extends NewBasePipeline>
	extends WorkflowModulesPack {

	private static Class<? extends WorkflowModule>[] defaultModules = [BuildModule.class]
	protected final Workflow workflow = Workflow.workflow
	protected final String name
	protected Var_Creds[] creds = []

	NewBasePipeline(String name, Class<? extends WorkflowModule>... modules) {
		super(ArrayTools.appendElements(defaultModules, modules))
		this.name = name
	}

	T setRequiredCredentials(Var_Creds... creds) {
		this.creds = creds
		return (T) this
	}

	T addStage(String name, Closure toRun) {
		workflow.addStage(name, toRun)
		return (T) this
	}

	void cd(String folder, Closure todo) {
		workflow.cd(folder, todo)
	}

	void withCredentials(Var_Creds[] params, Closure toRun) {
		workflow.withCredentials(params, toRun)
	}

	void run() {
		workflow.run()
	}

	abstract void pipeline()
}
