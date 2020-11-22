package com.nu.art.pipeline.modules.git

class GitRepoChangeSet {
	GitChangeLog[] log
	GitRepo repo
	String fromCommit
	String toCommit

	GitRepoChangeSet(GitRepo repo, String fromCommit, String toCommit) {
		this.repo = repo
		this.fromCommit = fromCommit
		this.toCommit = toCommit

	}

	GitRepoChangeSet init() {
		if (!toCommit)
			return this

		String changeLog = repo.executeCommand("git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue\"%an\" %Creset%s' --date=format:'%Y-%m-%d %H:%M:%S %z' ${fromCommit}...${toCommit}", true)
		if (changeLog.length() < 10)
			return this

		this.log = changeLog.split("\n").collect { commit ->
			repo.module.logDebug("commit: ${commit}")
			new GitChangeLog(commit)
		}
		this.log.reverse()
		return this
	}

	String toSlackMessage() {
		GitRepoConfig config = repo.config
		String repoUrl = "https://github.com/${config.group}/${config.repoName}"
		String repo = "<${repoUrl}|${config.repoName}>"
		String diff = "<${repoUrl}/compare/${toCommit}...${fromCommit}|diff> "
		String changeLog = "${repo} | ${diff}\n"
		log.collect({ "<${repoUrl}/commit/${it.hash}/|Changes> by *${it.author}*: ${it.comment}" }).each { changeLog += " - ${it}\n" }
		return changeLog
	}
}
