package com.nu.art.pipeline.thunderstorm.models

class ProjectGitConfig {
	String httpUrl
	String gitRepoUri
	Boolean scm

	ProjectGitConfig(String repoId, scm = false) {
		this("https://github.com/${repoId}", "git@github.com:${repoId}.git")
	}

	ProjectGitConfig(String httpUrl, String gitRepoUri, Boolean scm = false) {
		this.httpUrl = httpUrl
		this.gitRepoUri = gitRepoUri
		this.scm = scm
	}

	setHttpUrl(String httpUrl) {
		this.httpUrl = httpUrl
		return this
	}

	setGitRepoUri(String gitRepoUri) {
		this.gitRepoUri = gitRepoUri
		return this
	}

	setSCM(String scm) {
		this.scm = scm
		return this
	}
}
