package com.nu.art.pipeline.modules.build

class CopyArtifacts {
	BuildModule module
	String jobName
	String filter = "*"
	String output = "."
	def selector

	CopyArtifacts(BuildModule module) {
		this.module = module
	}

	CopyArtifacts job(String name, int build) {
		this.jobName = name
		this.selector = module.workflow.script.specific("${build}")
		return this
	}

	CopyArtifacts filter(String filter) {
		this.filter = filter
		return this
	}

	CopyArtifacts output(String output) {
		this.output = output
		return this
	}

	void copy() {
		module.workflow.script.copyArtifacts filter: filter,
			fingerprintArtifacts: true,
			projectName: jobName,
			selector: selector,
			target: output
	}

}
