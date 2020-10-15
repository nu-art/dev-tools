package com.nu.art.pipeline.workflow

import com.nu.art.belog.BeConfig
import com.nu.art.belog.BeLogged
import com.nu.art.belog.LoggerDescriptor
import com.nu.art.core.tools.ArrayTools
import com.nu.art.modular.core.ModuleManager
import com.nu.art.modular.core.ModuleManagerBuilder
import com.nu.art.pipeline.interfaces.Shell
import com.nu.art.pipeline.workflow.logs.Config_WorkflowLogger
import com.nu.art.pipeline.workflow.logs.WorkflowLogger
import com.nu.art.pipeline.workflow.variables.VarConsts
import com.nu.art.pipeline.workflow.variables.Var_Creds
import com.nu.art.pipeline.workflow.variables.Var_Env
import com.nu.art.reflection.tools.ReflectiveTools

@Grab('com.nu-art-software:module-manager:1.2.34')
@Grab('com.nu-art-software:reflection:1.2.34')
@Grab('com.nu-art-software:belog:1.2.34')
@Grab('com.google.code.gson:gson:2.8.6')


class Workflow
	extends ModuleManagerBuilder {

	static <T extends NewBasePipeline<T>> T createWorkflow(Class<T> pipelineType, def script) {
		workflow = new Workflow(script)

		BeLogged.getInstance().registerDescriptor(new LoggerDescriptor<Config_WorkflowLogger, WorkflowLogger>(Config_WorkflowLogger.KEY, Config_WorkflowLogger.class, WorkflowLogger.class))
		BeLogged.getInstance().setConfig(new BeConfig().setLoggersConfig(new Config_WorkflowLogger()).setRules(new BeConfig.Rule().setLoggerKeys("default")))

		T pipeline = ReflectiveTools.newInstance(pipelineType)
		workflow.addModulePacks(pipeline)
		workflow.build()
		workflow.start()

		VarConsts.Var_JobName = Var_Env.create("JOB_NAME")
		VarConsts.Var_BuildNumber = Var_Env.create("BUILD_NUMBER")
		VarConsts.Var_BuildUrl = Var_Env.create("BUILD_URL")
		VarConsts.Var_Workspace = Var_Env.create("WORKSPACE", { script.pwd() })

		script.ansiColor('xterm') {
			script.withCredentials(pipeline.creds.collect { param -> param.toCredential(script) }) {
				pipeline.pipeline()
				pipeline.run()
			}
		}
		return pipeline
	}

	static Workflow workflow
	private String currentStage = "IDLE"
	private String[] orderedStaged = []
	private LinkedHashMap<String, Closure> stages = [:]
	def script

	private Workflow(def script) {
		this.script = script
	}

	void start() {
		addStage("started", {
			this.dispatchEvent("Pipeline Started Event", OnPipelineListener.class, { listener -> listener.onPipelineStarted() } as WorkflowProcessor<OnPipelineListener>)
		})
	}

	private void setManager(ModuleManager manager) {
		this.manager = manager
	}

	@NonCPS
	protected void onApplicationStarting() {
		String art = "\n    ____  _            ___          \n" +
			"   / __ \\(_)___  ___  / (_)___  ___ \n" +
			"  / /_/ / / __ \\/ _ \\/ / / __ \\/ _ \\\n" +
			" / ____/ / /_/ /  __/ / / / / /  __/\n" +
			"/_/   /_/ .___/\\___/_/_/_/ /_/\\___/ \n" +
			"       /_/                          \n"
		logVerbose(" Pipeline Starting...")
		logVerbose("")
		logVerbose(art)
	}

	void addStage(String name, Closure toRun) {
		orderedStaged = ArrayTools.appendElement(orderedStaged, name)
		stages.put(name, toRun)
	}

	void run() {
		addStage("Completed", {
			this.dispatchEvent("Pipeline Completed Event", OnPipelineListener.class, { listener -> listener.onPipelineSuccess() } as WorkflowProcessor<OnPipelineListener>)
		})

		try {
			for (String stage : orderedStaged) {
				this.currentStage = stage
				logDebug("STAGE: ${stage}")
				script.stage(stage, stages[stage])
			}
		} catch (e) {
			logError("Error ${e.getMessage()}")
			this.dispatchEvent("Pipeline Error Event", OnPipelineListener.class, { listener -> listener.onPipelineFailed(e) } as WorkflowProcessor<OnPipelineListener>)
			throw e
		} finally {
			script.stage("finally", {
				logInfo("Ended")
			})
		}
	}

	private <T> void dispatchEvent(String message, Class<T> listenerType, WorkflowProcessor<T> processor) {
		this.manager.dispatchModuleEvent(this, message, listenerType, processor)
	}

	@NonCPS
	void log(String message) {
		script.echo message
	}

	@NonCPS
	void log(GString message) {
		script.echo message
	}

	void cd(String folder, Closure todo) {
		script.dir(folder) {
			todo.call()
		}
	}

	void sh(String command, Shell shell = null) {
		if (!shell)
			shell = script

		shell.sh(command)
	}

	@NonCPS
	String getEnvironmentVariable(String varName) {
		return script.env[varName]
	}

	void withCredentials(Var_Creds[] params, Closure toRun) {
		script.withCredentials(params.collect { param -> param.toCredential(script) }) {
			toRun()
		}
	}
}


