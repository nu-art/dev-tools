package com.nu.art.pipeline.modules.git

import com.nu.art.pipeline.exceptions.BadImplementationException;

class GitRepo {

	private GitRepoConfig config
	private GitModule module

	GitRepo(GitModule module, GitRepoConfig config) {
		this.module = module
		this.config = config
	}

	void cloneRepo() {
		String url = config.url.replace(".git", "")
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
														[$class: 'RelativeTargetDirectory', relativeTargetDir: config.outputFolder]],
				browser          : [$class: config.service, repoUrl: url],
				userRemoteConfigs: [[url: url + '.git']]
			]

		Closure updateSubmodules = {
			module.sh "git submodule update --recursive --init"
		}


		if (config.outputFolder != "")
			module.cd(config.outputFolder, updateSubmodules)
		else
			updateSubmodules.call()
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

	void createTag(String tagName) {
		if (!tagName)
			throw new BadImplementationException("tag name is undefined")

		module.cd(config.getOutputFolder()) {
			module.sh("git tag -f ${tagName}")
		}
	}

	void pushTags() {
		module.cd(config.getOutputFolder()) {
			module.sh("git push --tags")
		}
	}

	void push() {
		module.cd(config.getOutputFolder()) {
			module.sh("git push")
		}
	}

	void commit(String message) {
		module.cd(config.getOutputFolder()) {
			module.sh("git commit -am \"${message}\"")
		}
	}

	String getOutputFolder() {
		return config.outputFolder
	}

	String getBranch() {
		return config.branch
	}
}
