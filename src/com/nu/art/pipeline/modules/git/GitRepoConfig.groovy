package com.nu.art.pipeline.modules.git

class GitRepoConfig {
	final String url
	final String repoName

	String outputFolder

	String service = "GithubWeb"
	String branch = "master"
	String shallowClone = false
	Boolean changelog = true
	GitModule module

	GitRepoConfig(GitModule module, String url) {
		this.module = module
		this.url = url
		this.repoName = url.replace(".git", "").substring(url.lastIndexOf("/") + 1)
		this.outputFolder = this.repoName
	}

	GitRepoConfig setService(String service) {
		this.service = service
		return this
	}

	GitRepoConfig setBranch(String branch) {
		this.branch = branch
		return this
	}

	GitRepoConfig setOutputFolder(String outputFolder) {
		this.outputFolder = outputFolder
		return this
	}

	GitRepoConfig setShallowClone(String shallowClone) {
		this.shallowClone = shallowClone
		return this
	}

	GitRepoConfig setChangelog(Boolean changelog) {
		this.changelog = changelog
		return this
	}

	String getOutputFolder() {
		return outputFolder
	}

	GitModule.GitRepo build() {
		return module.createRepo(this)
	}
}
