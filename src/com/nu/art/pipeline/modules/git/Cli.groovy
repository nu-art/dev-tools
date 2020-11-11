package com.nu.art.pipeline.modules.git

class Cli<T extends Cli> {
	public static Cli _continue
	public static Cli _break
	public static Cli _return

	String script = ""
	Boolean async

	Cli(String shebang = "", async = false) {
		if (shebang.length() > 0)
			script = "${shebang}\n"

		this.async = async
	}

	static void init() {
		_continue = new Cli().append("continue")
		_break = new Cli().append("break")
		_return = new Cli().append("return")
	}

	T _if(String condition, Closure<Cli> ifBlock, Closure<Cli> elseBlock = null) {
		append("if ${condition}; then")
		append(ifBlock())

		if (elseBlock) {
			append("else")
			append(elseBlock())
		}

		append("fi")

		return (T) this
	}

	T _for(String varName, String arrayName, Closure<Cli> loop) {
		append("for ${varName} in \"\${${arrayName}[@]}\"; do")
		append(loop())
		append("done")
		append("")
	}

	T _for(String varName, String[] values, Closure<Cli> loop) {
		append("for ${varName} in ${values.collect({ "\"it\"" }).join(" ")}; do")
		append(loop())
		append("done")
		append("")
	}

	T ls(String params = "") {
		append("ls ${params}")
		return (T) this
	}

	T cd(String dir, Closure<Cli> toRun = null) {
		if (dir != "")
			append("cd ${dir}")

		if (toRun) {
			append(toRun())

			if (dir != "")
				append("cd -")
		}

		return (T) this
	}

	T pwd() {
		append("pwd")
		return (T) this
	}

	T assign(String varName, String value) {
		append("${varName}=${value}")
	}

	T assign(String varName, String[] value) {
		append("${varName}=(${value.join(" ")})")
	}

	T append(String command) {
		script = "${script}${command}${command.endsWith("\n") ? "" : "\n"}"

		return (T) this
	}

	T append(Cli cli) {
		String script = cli.script.replaceAll("^", "  ").replaceAll("\n", "\n  ")
		append(script.substring(0, script.length() - 2))
	}
}
