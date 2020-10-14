package com.nu.art.pipeline.workflow.variables

import com.nu.art.pipeline.interfaces.Getter
import com.nu.art.pipeline.workflow.Workflow

class Var_Env
	implements Getter<String> {

	final String varName
	final Getter<String> value

	static Var_Env create(String varName) {
		return new Var_Env(varName)
	}

	static Var_Env create(String varName, Getter<String> value) {
		return new Var_Env(varName, value)
	}


	Var_Env(String varName) {
		this(varName, { Workflow.workflow.getEnvironmentVariable(varName) })
	}

	Var_Env(String varName, Getter<String> value) {
		this.varName = varName
		this.value = value
	}

	String get() {
		return value.get()
	}
}
