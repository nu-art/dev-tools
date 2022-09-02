package com.nu.art.pipeline.modules.git

import com.nu.art.pipeline.modules.build.BuildModule

class GitRepo {

	GitRepoConfig config
	GitModule gitModule

	GitRepo(GitModule gitModule, GitRepoConfig config) {
		this.gitModule = gitModule
		this.config = config
	}

	void cloneRepo() {
		GitCli command = GitCli.create(this).clone(config)
		if (config.trackSubmodules)
			command.gsui()

		gitModule.logDebug("cloning repo(GIT): ${config.url}")
		gitModule.logDebug("${command.script}")
		gitModule.sh(command.script)
		gitModule.gitStatusSave(this)
	}

	void cloneSCM() {
		if (!config.trackSCM)
			return

		String url = config.url.replace(".git", "")
		String outputFolder = config.url.replace(".git", "").substring(url.lastIndexOf("/") + 1)

		gitModule.logDebug("cloning repo(SCM): ${config.url}")

		gitModule.workflow.script.checkout changelog: config.changelog,
			scm: [
				$class           : 'GitSCM',
				branches         : [[name: config.branch]],
				extensions       : [[$class: 'LocalBranch', localBranch: "**"],
														[$class             : 'SubmoduleOption',
														 disableSubmodules  : true,
														 parentCredentials  : true,
														 recursiveSubmodules: true,
														 reference          : '',
														 trackingSubmodules : false],
														[$class: 'CloneOption', noTags: false, reference: '', shallow: config.shallowClone],
														[$class: 'CheckoutOption'],
														[$class: 'UserExclusion', excludedUsers: "Nu-Art-Jenkins\nNu-Art Jenkins\n"],
														[$class: 'RelativeTargetDirectory', relativeTargetDir: "__${outputFolder}"]],
				browser          : [$class: config.service, repoUrl: url],
				userRemoteConfigs: [[url: url + '.git']]
			]
	}

	GitCli cli() {
		GitCli.create(this)
	}

	String currentBranch() {
		return sh(cli().getCurrentBranch(), true)
	}

	void assertCommitDiffs(Closure action = null) {
		sh(cli().append("git clone ${this.config.url} --depth 1 --branch ${this.config.branch} _temp"))
		String commitId = sh("cd _temp; git show HEAD --pretty=format:\"%H\" --no-patch", true)


	}

	void checkout(String branch, force = false) {
		try {
			sh(cli().checkout(branch))
		} catch (e) {
			if (!force)
				throw e

			if (currentBranch() != branch)
				sh(cli().createBranch(branch))
		}
	}

	void merge(String commitTag) {
		sh(cli().merge(commitTag))
	}

	void createTag(String tagName) {
		sh(cli().createTag(tagName))
	}

	void pushTags() {
		sh(cli().pushTags())
	}

	void gsui() {
		sh(cli().gsui())
	}

	void push() {
		sh(cli().push())
	}

	void commit(String message) {
		sh(cli().commit(message))
	}

	@Deprecated
	String executeCommand(Cli cli, output = false) {
		sh(cli.script, output)
	}

	@Deprecated
	String executeCommand(String command, output = false) {
		gitModule.logVerbose("command: ${command}")
		return gitModule.cd(config.getOutputFolder()) {
			return gitModule.sh(command, output)
		}
	}

	String sh(Cli cli, output = false) {
		sh(cli.script, output)
	}

	String sh(String command, output = false) {
		gitModule.logVerbose("command: ${command}")
		return gitModule.cd(config.getOutputFolder()) {
			return gitModule.sh(command, output)
		}
	}

	String getUrl() {
		return config.url
	}

	String getOutputFolder() {
		return config.outputFolder
	}

	String getBranch() {
		return config.branch
	}

	String getCurrentCommit() {
		return sh("git show HEAD --pretty=format:\"%H\" --no-patch", true)
	}


	GitRepoChangeSet getChangeLog(String fromCommit = getCurrentCommit(), String toCommit = null) {
		if (!toCommit)
			toCommit = gitModule.gitStatus(this)?.commitId

		try {
			return new GitRepoChangeSet(this, fromCommit, toCommit).init()
		} catch (Exception e) {
			gitModule.logWarning("Failed to get changelog: ${e.getMessage()}")
			return new GitRepoChangeSet(this, fromCommit, null).init()
		}
	}

	String pathToFile(String relativePath) {
		return gitModule.getModule(BuildModule.class).pathToFile("${config.outputFolder}/${relativePath}")
	}
}