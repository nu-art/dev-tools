package com.nu.art.pipeline.workflow

import com.nu.art.pipeline.modules.build.BuildModule
import com.nu.art.pipeline.modules.build.JobTrigger
import com.nu.art.pipeline.workflow.variables.VarConsts
import com.nu.art.pipeline.workflow.variables.Var_Creds
import com.nu.art.pipeline.workflow.variables.Var_Env

abstract class BasePipeline<T extends BasePipeline>
	extends WorkflowModulesPack {

	public Var_Env Var_CleanWorkspace = new Var_Env("CLEAN_WORKSPACE")

	private static Class<? extends WorkflowModule>[] defaultModules = [BuildModule.class]
	protected final Workflow workflow = Workflow.workflow

	protected final String name
	protected Var_Creds[] creds = []

	BasePipeline(String name, Class<? extends WorkflowModule>... modules) {
		super(defaultModules + modules)
		this.name = name
	}

	T printEnvParams(Var_Env... envVars) {
		envVars.each { workflow.logDebug("${it.varName} == ${it.get()}") }
		return (T) this
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

	JobTrigger triggerJob(String name) {
		return getModule(BuildModule.class).triggerJob(name)
	}

	String getName() {
		return name
	}

	void run() {
		setDisplayName()
		workflow.run()
	}

	abstract void pipeline()

	void _postInit() {}

	void setDisplayName() {
		getModule(BuildModule.class).setDisplayName("#${VarConsts.Var_BuildNumber.get()}: ${name}")
	}

	void cleanup() {
		if (Var_CleanWorkspace.get())
			workflow.deleteWorkspace()
	}
}
