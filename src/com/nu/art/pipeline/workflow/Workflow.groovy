package com.nu.art.pipeline.workflow

import com.cloudbees.groovy.cps.NonCPS
import com.nu.art.belog.BeConfig
import com.nu.art.belog.BeLogged
import com.nu.art.belog.LoggerDescriptor
import com.nu.art.core.tools.ArrayTools
import com.nu.art.modular.core.ModuleManager
import com.nu.art.modular.core.ModuleManagerBuilder
import com.nu.art.pipeline.exceptions.BadImplementationException
import com.nu.art.pipeline.modules.git.Cli
import com.nu.art.pipeline.workflow.logs.Config_WorkflowLogger
import com.nu.art.pipeline.workflow.logs.WorkflowLogger
import com.nu.art.pipeline.workflow.variables.VarConsts
import com.nu.art.pipeline.workflow.variables.Var_Creds
import com.nu.art.pipeline.workflow.variables.Var_Env
import com.nu.art.reflection.tools.ReflectiveTools
import org.jenkinsci.plugins.workflow.cps.CpsScript
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

@Grab('com.nu-art-software:module-manager:1.2.34')
@Grab('com.nu-art-software:reflection:1.2.34')
@Grab('com.nu-art-software:belog:1.2.34')
@Grab('com.google.code.gson:gson:2.8.6')


class Workflow
	extends ModuleManagerBuilder {

	static <T extends BasePipeline<T>> T createWorkflow(Class<T> pipelineType, def script) {
		workflow = new Workflow(script)

		BeLogged.getInstance().registerDescriptor(new LoggerDescriptor<Config_WorkflowLogger, WorkflowLogger>(Config_WorkflowLogger.KEY, Config_WorkflowLogger.class, WorkflowLogger.class))
		BeLogged.getInstance().setConfig(new BeConfig().setLoggersConfig(new Config_WorkflowLogger()).setRules(new BeConfig.Rule().setLoggerKeys("default")))

		Cli.init()

		VarConsts.Var_JenkinsHome = Var_Env.create("JENKINS_HOME")
		VarConsts.Var_JobName = Var_Env.create("JOB_NAME")
		VarConsts.Var_BuildNumber = Var_Env.create("BUILD_NUMBER")
		VarConsts.Var_UserEmail = Var_Env.create("BUILD_USER_EMAIL")
		VarConsts.Var_BuildUrl = Var_Env.create("BUILD_URL")
		VarConsts.Var_Workspace = Var_Env.create("WORKSPACE", { script.pwd() })

		T pipeline = ReflectiveTools.newInstance(pipelineType)
		workflow.setPipeline(pipeline)
		workflow.addModulePacks(pipeline)
		workflow.build()
		workflow.start()


		script.ansiColor('xterm') {
			script.withCredentials(pipeline.creds.collect { param -> param.toCredential(script) }) {
				workflow.script.wrap([$class: 'BuildUser']) {
					pipeline.pipeline()
					pipeline.run()
				}
			}
		}
		return pipeline
	}

	public static final String Stage_IDLE = "IDLE"
	public static final String Stage_Started = "Started"
	public static final String Stage_Cleanup = "Cleanup"
	public static final String Stage_Completed = "Completed"
	public static final String Stage_Finally = "Finally"

	static Workflow workflow
	BasePipeline pipeline
	String currentStage = Stage_IDLE
	private String[] orderedStaged = []
	private LinkedHashMap<String, Closure> stages = [:]
	CpsScript script

	private Workflow(def script) {
		this.script = script
	}

	private void setPipeline(BasePipeline pipeline) {
		this.pipeline = pipeline
	}

	void start() {
		addStage(Stage_Started, {
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
		stages.put(name, { toRun() })
	}

	void run() {
		Throwable t = null

		for (String stage : orderedStaged) {
			this.currentStage = stage
			logDebug("STAGE: ${stage}")
			try {
				script.stage(stage, {
					if (t)
						throw t

					stages[stage]()
				})
			} catch (e) {
				logError("Error in stage '${stage}': ${t.getMessage()}", e)
				t = e
			}
		}

		try {
			script.stage(Stage_Cleanup, {
				pipeline.cleanup()
			})
		} catch (e) {
			logError("Error in 'cleanup' stage: ${t.getMessage()}", e)
			t = e
		}

		try {
			script.stage(Stage_Completed, {
				if (!t) {
					this.dispatchEvent("Pipeline Completed Event", OnPipelineListener.class, { listener -> listener.onPipelineSuccess() } as WorkflowProcessor<OnPipelineListener>)
				} else {
					this.dispatchEvent("Pipeline Error Event", OnPipelineListener.class, { listener -> listener.onPipelineFailed(t) } as WorkflowProcessor<OnPipelineListener>)
				}
			})
		} catch (e) {
			logError("Error in 'completion' stage: ${t.getMessage()}", e)
			t = e
		}

		if (t)
			throw t

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

	def <R> R cd(String folder, Closure<R> todo) {
		R toRet
		script.dir(folder) {
			toRet = todo.call()
		}

		//noinspection GroovyVariableNotAssigned
		return (R) toRet
	}

	String sh(String command, readOutput = false) {
		return script.sh(script: command, returnStdout: readOutput)
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

	RunWrapper getCurrentBuild() {
		return script.currentBuild
	}

	boolean fileExists(String pathToFile) {
		return script.fileExists(pathToFile)
	}

	String readFile(String pathToFile) {
		if (!fileExists(pathToFile))
			throw new BadImplementationException("Could not find file: ${pathToFile}")

		return script.readFile(pathToFile)
	}

	void writeToFile(String pathToFile, String content) {
		script.writeFile file: pathToFile, text: content
	}

	void archiveArtifacts(String pattern, boolean onlyIfSuccessful = true) {
		script.archiveArtifacts artifacts: pattern, onlyIfSuccessful: onlyIfSuccessful
	}

	void deleteWorkspace() {
		script.deleteDir()
	}
}


