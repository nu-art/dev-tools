package com.nu.art.pipeline.modules.git.models

class GitStatus {
	String branch
	String commitId

	GitStatus(String branch, String commitId) {
		this.branch = branch
		this.commitId = commitId
	}

	GitStatus() {}
}
