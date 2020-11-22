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
		this.log.reverse()
	}

	GitRepoChangeSet(GitRepo repo, String fromCommit, String toCommit) {
		this.repo = repo
		this.fromCommit = fromCommit
		this.toCommit = toCommit
	}

	String toSlackMessage() {
		GitRepoConfig config = repo.config
		String repoUrl = "https://github.com/${config.group}/${config.repoName}"
		String repo = "<${repoUrl}|${config.repoName}>"
		String diff = "<${repoUrl}/compare/${toCommit}...${fromCommit}|diff> "
		String changeLog = "${repo} | ${diff}\n"
		log.collect({ "<${repoUrl}/commit/${it.hash}/|Changes> by <https://github.com/${it.author}|${it.author}>: ${it.comment}" }).each { changeLog += " * ${it}\n" }
		return changeLog
	}
}
