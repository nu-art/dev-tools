package com.nu.art.pipeline.modules.git

import com.nu.art.pipeline.modules.build.BuildModule
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.utils.Utils
import com.nu.art.pipeline.workflow.variables.VarConsts
import groovy.json.JsonOutput
import groovy.transform.PackageScope
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

class GitModule
	extends WorkflowModule {

	private HashMap<String, GitCheckoutStatus> commitStatus = [:]
	private String checkoutStatusFileName = "checkout-status.json"

	@PackageScope
	GitRepo createRepo(GitRepoConfig config) {
		return new GitRepo(this, config)
	}

	GitRepoConfig create(String url) {
		return new GitRepoConfig(this, url)
	}

	void setCommit(GitRepo repo) {
		String commitId = repo.getCurrentCommit(repo)
		commitStatus.put(repo.getUrl(), new GitCheckoutStatus(commitId))
		String pathToFile = getModule(BuildModule.class).pathToFile(checkoutStatusFileName)
		workflow.writeToFile(pathToFile, JsonOutput.toJson(commitStatus))
		workflow.archiveArtifacts checkoutStatusFileName
	}

	GitCheckoutStatus getCommit(GitRepo repo, RunWrapper build) {
		getModule(BuildModule.class)
			.copyArtifacts(VarConsts.Var_JobName.get(), build.getNumber())
			.filter(checkoutStatusFileName)
			.output(".input")
			.copy()

		String pathToFile = ".input/${checkoutStatusFileName}"
		if (!workflow.fileExists(pathToFile))
			return null

		String fileContent = workflow.readFile(pathToFile)
		def checkoutStatus = Utils.parse(fileContent, HashMap.class) as HashMap<String, GitCheckoutStatus>
		return checkoutStatus[repo.getUrl()]
	}
}

