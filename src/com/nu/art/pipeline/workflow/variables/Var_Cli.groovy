package com.nu.art.pipeline.workflow.variables


import com.nu.art.pipeline.interfaces.Getter

class Var_Cli
	implements IVar_Cli {

	static String buildCommand(String command, Var_Cli... params) {
		List<String> _params = params.collect { param -> "--${param.key()}=${param.get()}".toString() }
		String paramsAsString = ""
		for (i in 0..<_params.size()) {
			paramsAsString += " ${_params.get(i)}"
		}
		return "${command} ${paramsAsString}"
	}

	static Var_Cli create(String varName, Getter<String> getter) {
		return new Var_Cli(varName, { getter.get() })
	}

	static Var_Cli create(String varName, Var_Env value) {
		return new Var_Cli(varName, { value.get() })
	}

	static Var_Cli create(String varName, String value) {
		return new Var_Cli(varName, { value })
	}

	final String varName
	final Closure<String> value

	private Var_Cli(String varName, Closure<String> value) {
		this.varName = varName
		this.value = value
	}

	@Override
	String key() {
		return varName
	}

	@Override
	String get() {
		return value()
	}
}
