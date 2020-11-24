package com.nu.art.pipeline.modules.git.models

class GitStatus_Repo
	extends HashMap<String, GitStatus> {

	String repoUrl

	GitStatus_Repo(String repoUrl) {
		this.repoUrl = repoUrl

	}

	GitStatus_Repo() {}
}
