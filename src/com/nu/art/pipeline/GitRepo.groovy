package com.nu.art.pipeline

import com.nu.art.exception.BadImplementationException

class GitRepo {

  final MyPipeline pipeline
  final String url

  String service = "GithubWeb"
  String branch = "master"
  String folderName = ""
  String shallowClone = false
  Boolean changelog = true

  GitRepo(MyPipeline pipeline, String url) {
    this.pipeline = pipeline
    this.url = url
    this.folderName = url.replace(".git", "").substring(url.lastIndexOf("/"))
  }

  cloneRepo() {
    String url = this.url.replace(".git", "")
    pipeline.script.checkout changelog: changelog,
      scm: [
        $class           : 'GitSCM',
        branches         : [[name: branch]],
        timeout          : 30,
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

    Closure updateSubmodules = (pipeline) -> {
      pipeline.sh "git submodule update --recursive --init"
    }

    if (folderName != "")
      pipeline.cd(folderName, updateSubmodules)
    else
      updateSubmodules(pipeline)
  }

  createTag(String tagName) {
    if (!tagName)
      throw new BadImplementationException("tag name is undefined")

    pipeline.sh("git tag -f ${tagName}")
  }

  pushTags() {
    pipeline.sh("git push --tags")
  }

  push() {
    pipeline.sh("git push")
  }

  commit(String message) {
    pipeline.sh("git commit -am \"${message}\"")
  }
}

