package com.nu.art.pipeline.modules.git

class GitRepoConfig {
	final String url
	final String repoName
	final String group

	String outputFolder

	String service = "GithubWeb"
	String branch = "master"
	Boolean shallowClone = false
	Boolean trackSubmodules = true
	Boolean changelog = true
	GitModule module
	boolean trackSCM = true

	GitRepoConfig(GitModule module, String url) {
		this.module = module
		this.url = url
		this.repoName = url.replace(".git", "").substring(url.lastIndexOf("/") + 1)
		this.group = url.substring(url.indexOf(":") + 1,url.lastIndexOf("/"))
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

	GitRepoConfig setShallowClone(Boolean shallowClone) {
		this.shallowClone = shallowClone
		return this
	}

	GitRepoConfig setTrackSubmodules(Boolean trackSubmodules) {
		this.trackSubmodules = trackSubmodules
		return this
	}

	GitRepoConfig setChangelog(Boolean changelog) {
		this.changelog = changelog
		return this
	}

	GitRepoConfig setTrackSCM(boolean trackSCM) {
		this.trackSCM = trackSCM
		return this
	}

	String getOutputFolder() {
		return outputFolder
	}

	GitRepo build() {
		return module.createRepo(this)
	}
}
