package com.nu.art.pipeline.workflow.variables


import com.nu.art.pipeline.interfaces.Getter

class Var_Creds
	implements Getter<String> {

	final String type
	final String id
	final Var_Env envVar

	Var_Creds(String type, String id) {
		this(type, id, null)
	}

	Var_Creds(String type, String id, Var_Env envVar) {
		this.type = type
		this.id = id
		this.envVar = envVar
	}

	@Override
	String get() {
		return envVar.get()
	}

	Object toCredential(def script) {
		return script."$type"(credentialsId: id, variable: envVar.varName)
	}
}
