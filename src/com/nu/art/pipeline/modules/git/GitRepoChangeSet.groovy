package com.nu.art.pipeline.modules.git

class GitRepoChangeSet {
	GitChangeLog[] log
	GitRepo repo
	String fromCommit
	String toCommit

	GitRepoChangeSet(GitRepo repo, String fromCommit, String toCommit, String changeLog) {
		this(repo, fromCommit, toCommit)
		if (changeLog.length() < 10)
			return

		this.log = changeLog.split("\n").collect { commit -> new GitChangeLog(commit) }
	}

	GitRepoChangeSet(GitRepo repo, String fromCommit, String toCommit) {
		this.repo = repo
		this.fromCommit = fromCommit
		this.toCommit = toCommit
	}
}
