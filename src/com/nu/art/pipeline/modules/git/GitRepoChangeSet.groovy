package com.nu.art.pipeline.modules.git

class GitRepoChangeSet {
	GitChangeLog[] log
	GitRepo repo

	GitRepoChangeSet(GitRepo repo, String changeLog) {
		this(repo)
		this.log = changeLog.split("\n").collect { commit -> new GitChangeLog(commit) }
	}

	GitRepoChangeSet(GitRepo repo) {
		this.repo = repo
	}
}
