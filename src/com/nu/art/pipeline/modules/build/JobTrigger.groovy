package com.nu.art.pipeline.modules.build

import com.nu.art.pipeline.workflow.Workflow
import com.nu.art.pipeline.workflow.variables.Var_Env
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

class JobTrigger
	implements Serializable {

	String name
	Workflow workflow
	def params = []
	boolean wait = true

	JobTrigger(Workflow workflow, String name) {
		this.name = name
		this.workflow = workflow
	}

	JobTrigger addString(String key, String value) {
		return this.addParam(JobParam.Param_String, key.toString(), value)
	}

	JobTrigger addString(Var_Env envVar) {
		return this.addParam(JobParam.Param_String, envVar.varName, envVar.get())
	}

	JobTrigger addBoolean(String key, Boolean value) {
		return this.addParam(JobParam.Param_Boolean, key.toString(), value)
	}

	JobTrigger setWait(boolean wait) {
		this.wait = wait
		return this
	}

	private <T> JobTrigger addParam(JobParam<T> type, String key, T value) {
		params += [$class: type.key, name: key, value: value.toString()]
		return this
	}

	RunWrapper run() {
		RunWrapper result = workflow.script.build job: name, parameters: params, wait: wait
		return result
	}
}
