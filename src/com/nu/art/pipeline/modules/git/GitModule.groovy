package com.nu.art.pipeline.modules.git


import com.nu.art.pipeline.exceptions.BadImplementationException
import com.nu.art.pipeline.workflow.WorkflowModule
import groovy.transform.PackageScope

class GitModule
	extends WorkflowModule {

	@PackageScope
	GitRepo createRepo(GitRepoConfig config) {
		return new GitRepo(config)
	}

	GitRepoConfig create(String url) {
		return new GitRepoConfig(this, url)
	}

}

