package com.nu.art.pipeline

import com.nu.art.pipeline.exceptions.BadImplementationException

class GitRepo {

  final String url

  String service = "GithubWeb"
  String branch = "master"
  String folderName = ""
  String shallowClone = false
  Boolean changelog = true

  GitRepo(String url) {
    this.url = url
    this.folderName = url.replace(".git", "").substring(url.lastIndexOf("/") + 1)
  }

  void cloneRepo() {
    String url = this.url.replace(".git", "")
    BasePipeline.instance.script.checkout changelog: changelog,
      scm: [
        $class           : 'GitSCM',
        branches         : [[name: branch]],
        extensions       : [[$class: 'LocalBranch', localBranch: "**"],
                            [$class             : 'SubmoduleOption',
                             disableSubmodules  : true,
                             parentCredentials  : true,
                             recursiveSubmodules: true,
                             reference          : '',
                             trackingSubmodules : false],
                            [$class: 'CloneOption', noTags: false, reference: '', shallow: shallowClone],
                            [$class: 'CheckoutOption'],
                            [$class: 'RelativeTargetDirectory', relativeTargetDir: folderName]],
        browser          : [$class: "${service}", repoUrl: url],
        userRemoteConfigs: [[url: url + '.git']]
      ]

    Closure updateSubmodules = {
      BasePipeline.instance.sh "git submodule update --recursive --init"
    }


    if (folderName != "")
      BasePipeline.instance.cd(folderName, updateSubmodules)
    else
      updateSubmodules.call()
  }

  void createFullChangelog() {
    log
    logger.info "### Create full changelog "
    script.sh """echo 'Full Changelog:' > ${script.env.WORKSPACE}/full_changelog.txt """
    script.sh """echo '--------------------------------------------------------------' >> ${script.env.WORKSPACE}/full_changelog.txt """
    script.sh """echo '' >> ${script.env.WORKSPACE}/full_changelog.txt """
    def commitsIdsList = script.currentBuild.changeSets.collect({ it.items.collect { it.commitId } })
    for (int i = 0; i < commitsIdsList.size(); i++) {
      def commitsIds = commitsIdsList[i]
      for (int j = 0; j < commitsIds.size(); j++) {
        String commitInfo = script.sh(returnStdout: true, script: "git show -s ${commitsIds[j]} || true").trim()
        String commitInfoFiles = script.sh(returnStdout: true, script: "git diff-tree --no-commit-id --name-only -r ${commitsIds[j]} || true").trim()
        // Add submodules changes by running 'git show <commitid> <submodule>' for each changed submodule
        commitInfo = commitInfo.replaceAll("\"", " ").replaceAll("'", " ")
        commitInfoFiles = commitInfoFiles.replaceAll("\"", "").replaceAll("'", "")
        if (commitInfo != "") {
          script.sh """echo '${commitInfo}' >> ${script.env.WORKSPACE}/full_changelog.txt """
          script.sh """echo '${commitInfoFiles}' >> ${script.env.WORKSPACE}/full_changelog.txt """
          script.sh """echo '--------------------------------------------------------------' >> ${script.env.WORKSPACE}/full_changelog.txt """
          script.sh """echo '' >> ${script.env.WORKSPACE}/full_changelog.txt """
        }
      }
    }
  }

  GitRepo setService(String service) {
    this.service = service
    return this
  }

  GitRepo setBranch(String branch) {
    this.branch = branch
    return this
  }

  GitRepo setFolderName(String folderName) {
    this.folderName = folderName
    return this
  }

  GitRepo setShallowClone(String shallowClone) {
    this.shallowClone = shallowClone
    return this
  }

  GitRepo setChangelog(Boolean changelog) {
    this.changelog = changelog
    return this
  }

  void createTag(String tagName) {
    if (!tagName)
      throw new BadImplementationException("tag name is undefined")

    BasePipeline.instance.sh("git tag -f ${tagName}")
  }

  void pushTags() {
    BasePipeline.instance.sh("git push --tags")
  }

  void push() {
    BasePipeline.instance.sh("git push")
  }

  void commit(String message) {
    BasePipeline.instance.sh("git commit -am \"${message}\"")
  }
}

