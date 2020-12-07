package com.nu.art.pipeline.modules.git

class GitCli
	extends Cli<GitCli> {

	private GitRepo repo
	boolean skipSubmodules

	static GitCli create(GitRepo repo = null, async = false) {
		return new GitCli(repo, async)
	}

	GitCli(GitRepo repo, async = false) {
		super(repo ? "#!/bin/bash" : "", async)
		this.repo = repo
	}

	GitCli clone(GitRepoConfig config) {
		_if("[[ -e ${config.outputFolder ? config.outputFolder + "/" : ""}.git ]]", {
			create()
				.cd(config.outputFolder)
				.resetHard("origin/${config.branch}")
				.fetch()
				.checkout(config.branch)
				.append("git branch --set-upstream-to=origin/${config.branch} ${config.branch}\n")
				.pull("--ff-only")
		}, {
			create()
				.append("git clone ${config.url} --branch ${config.branch} ${config.outputFolder}")
				.cd(config.outputFolder)
		})

		return this
	}

	GitCli fetch() {
		append("git fetch")
		return this
	}

	GitCli resetHard(String tag = "") {
		append("git reset --hard ${tag}")
		return this
	}

	GitCli getCurrentBranch() {
		append("git status | grep \"On branch\" | sed -E \"s")
		return this
	}

	GitCli pull(String params) {
		append("git pull ${params}")
		return this
	}

	GitCli push() {
		append("git push")
		return this
	}

	GitCli createTag(String tagName) {
		append("git tag -f ${tagName}")
		return this
	}

	GitCli merge(String commitTag) {
		append("git merge ${commitTag}")
		return this
	}

	GitCli pushTags() {
		append("git push --tags")
		return this
	}

	GitCli checkout(String branch) {
		append("git checkout ${branch}")
		return this
	}

	GitCli commit(String message) {
		append("git commit -am \"${message}\"")
		return this
	}

	GitCli createBranch(String branch) {
		append("""
			git checkout - b ${branch}
			git push-- set -upstream origin ${branch}
			""")
		return this
	}

	GitCli gsui(String modules = "") {
		append("git submodule update --recursive --init ${modules}")
		return this
	}

	GitCli status() {
		append("git status")
		return this
	}

	GitCli alignSubmodules() {
		if (skipSubmodules)
			return this

		String submodulesOutput = repo.executeCommand("git submodule", true)
		String[] submodules = submodulesOutput.split("\n").collect({
			String substring = it.substring(it.indexOf(" ", 2) + 1, it.lastIndexOf(" "))
			return "\"${substring}\""
		})
		assign("GIT_SUBMODULES", submodules)
	}

	GitCli forAll(Closure<GitCli> inEach, String... toIgnore) {
		forEach(inEach, toIgnore)
		append(inEach().script)

		return this
	}

	GitCli forEach(Closure<GitCli> inEach, String... toIgnore) {
		if (skipSubmodules)
			return this

		GitCli commandCli = inEach()

		String condition = toIgnore.collect({
			"[[ \"${it}\" == \"\${GIT_SUBMODULE}\" ]]"
		}).join(" && ")

		append("echo \"\${GIT_SUBMODULES[@]}\"")
		_for("GIT_SUBMODULE", "GIT_SUBMODULES", {
			create()._if(condition, {
				_continue
			}, {
				create()
					.cd("\${GIT_SUBMODULE}", {
						create().append("(${commandCli.script.replaceAll("\n", "; ")})${commandCli.async ? "&" : ""};")
							.append("ERROR_CODE=\$?")
							.append("[[ \${ERROR_CODE} != 0 ]] && echo \"error... \" && exit \${ERROR_CODE}")
					})
			})
		})

		return this
	}

	void execute(output = false) {
		repo.executeCommand(this, output)
	}

	GitCli skipSubmodules(skipSubmodules = true) {
		this.skipSubmodules = skipSubmodules
		return this
	}
}