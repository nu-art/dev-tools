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
}
