package com.nu.art.pipeline.modules.git

import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

class GitRepo {

	GitRepoConfig config
	private GitModule module

	GitRepo(GitModule module, GitRepoConfig config) {
		this.module = module
		this.config = config
	}

	void cloneRepo() {
		GitCli command = GitCli.create(this).clone(config)
		if (config.trackSubmodules)
			command.gsui()

		module.logDebug("clonning repo(GIT): ${config.url}")
		module.logDebug("${command.script}")
		module.sh(command.script)
		module.setCommit(this)
	}

	void cloneSCM() {
		if (!config.trackSCM)
			return

		String url = config.url.replace(".git", "")
		String outputFolder = config.url.replace(".git", "").substring(url.lastIndexOf("/") + 1)

		module.logDebug("clonning repo(SCM): ${config.url}")

		module.workflow.script.checkout changelog: config.changelog,
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
														[$class: 'RelativeTargetDirectory', relativeTargetDir: "__${outputFolder}"]],
				browser          : [$class: config.service, repoUrl: url],
				userRemoteConfigs: [[url: url + '.git']]
			]
	}

	GitCli cli() {
		GitCli.create(this)
	}

	String currentBranch() {
		return executeCommand(cli().getCurrentBranch(), true)
	}

	void checkout(String branch, force = false) {
		try {
			executeCommand(cli().checkout(branch))
		} catch (e) {
			if (!force)
				throw e

			if (currentBranch() != branch)
				executeCommand(cli().createBranch(branch))
		}
	}

	void merge(String commitTag) {
		executeCommand(cli().merge(commitTag))
	}

	void createTag(String tagName) {
		executeCommand(cli().createTag(tagName))
	}

	void pushTags() {
		executeCommand(cli().pushTags())
	}

	void gsui() {
		executeCommand(cli().gsui())
	}

	void push() {
		executeCommand(cli().push())
	}

	void commit(String message) {
		executeCommand(cli().commit(message))
	}

	String executeCommand(Cli cli, output = false) {
		executeCommand(cli.script, output)
	}

	String executeCommand(String command, output = false) {
		module.logVerbose("command: ${command}")
		return module.cd(config.getOutputFolder()) {
			return module.sh(command, output)
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
		return executeCommand("git show HEAD~2 --pretty=format:\"%H\" --no-patch", true)
	}

	String getLastSuccessfulCommit() {
		RunWrapper lastSuccessfulBuild = module.workflow.getCurrentBuild().getPreviousSuccessfulBuild()
		return module.getCommit(this, lastSuccessfulBuild)
	}

	String[] getChangeLog(String current = getCurrentCommit(), String pastCommit = getLastSuccessfulCommit()) {
		if(!pastCommit)
			return

		executeCommand("git diff ${current}...${pastCommit}")
		executeCommand("git diff ${current}..${pastCommit}")
		executeCommand("git diff ${current}^..${pastCommit}")
	}
}

//  void createFullChangelog() {
//    log
//    logger.info "### Create full changelog "
//    script.sh """echo 'Full Changelog:' > ${script.env.WORKSPACE}/full_changelog.txt """
//    script.sh """echo '--------------------------------------------------------------' >> ${script.env.WORKSPACE}/full_changelog.txt """
//    script.sh """echo '' >> ${script.env.WORKSPACE}/full_changelog.txt """
//    def commitsIdsList = script.currentBuild.changeSets.collect({ it.items.collect { it.commitId } })
//    for (int i = 0; i < commitsIdsList.size(); i++) {
//      def commitsIds = commitsIdsList[i]
//      for (int j = 0; j < commitsIds.size(); j++) {
//        String commitInfo = script.sh(returnStdout: true, script: "git show -s ${commitsIds[j]} || true").trim()
//        String commitInfoFiles = script.sh(returnStdout: true, script: "git diff-tree --no-commit-id --name-only -r ${commitsIds[j]} || true").trim()
//        // Add submodules changes by running 'git show <commitid> <submodule>' for each changed submodule
//        commitInfo = commitInfo.replaceAll("\"", " ").replaceAll("'", " ")
//        commitInfoFiles = commitInfoFiles.replaceAll("\"", "").replaceAll("'", "")
//        if (commitInfo != "") {
//          script.sh """echo '${commitInfo}' >> ${script.env.WORKSPACE}/full_changelog.txt """
//          script.sh """echo '${commitInfoFiles}' >> ${script.env.WORKSPACE}/full_changelog.txt """
//          script.sh """echo '--------------------------------------------------------------' >> ${script.env.WORKSPACE}/full_changelog.txt """
//          script.sh """echo '' >> ${script.env.WORKSPACE}/full_changelog.txt """
//        }
//      }
//    }
//  }
