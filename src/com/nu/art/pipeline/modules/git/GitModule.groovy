package com.nu.art.pipeline.modules.git

import com.nu.art.pipeline.modules.build.BuildModule
import com.nu.art.pipeline.modules.git.models.GitStatus
import com.nu.art.pipeline.modules.git.models.GitStatus_Job
import com.nu.art.pipeline.modules.git.models.GitStatus_Repo
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.utils.Utils
import com.nu.art.pipeline.workflow.variables.VarConsts
import groovy.json.JsonOutput
import groovy.transform.PackageScope
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

class GitModule
	extends WorkflowModule {

	private GitStatus_Job commitStatus = [:]
	private String checkoutStatusFileName = "checkout-status.json"

	@PackageScope
	GitRepo createRepo(GitRepoConfig config) {
		return new GitRepo(this, config)
	}

	GitRepoConfig create(String url) {
		return new GitRepoConfig(this, url)
	}

	void gitStatusSave(GitRepo repo) {
		String commitId = repo.getCurrentCommit()
		GitStatus_Repo repoStatus = commitStatus.get(repo.getUrl())
		if (!repoStatus)
			commitStatus.put(repo.getUrl(), repoStatus = new GitStatus_Repo(repo.getUrl()))

		repoStatus.put(repo.config.branch, new GitStatus(repo.config.branch, commitId))
		commitStatus.put(repo.getUrl(), repoStatus)
		String pathToFile = getModule(BuildModule.class).pathToFile(checkoutStatusFileName)
		workflow.writeToFile(pathToFile, JsonOutput.toJson(commitStatus))
		workflow.archiveArtifacts checkoutStatusFileName
	}

	GitStatus gitStatus(GitRepo repo, RunWrapper build) {
		try {
			getModule(BuildModule.class)
				.copyArtifacts(VarConsts.Var_JobName.get(), build.getNumber())
				.filter(checkoutStatusFileName)
				.output(".input")
				.copy()
		} catch (e) {
			logError("Failed to resolve checkout status file from previous successful build", e)
			return null
		}

		String pathToFile = ".input/${checkoutStatusFileName}"
		if (!workflow.fileExists(pathToFile))
			return null

		String fileContent = workflow.readFile(pathToFile)
		GitStatus_Job checkoutStatus = Utils.parse(fileContent, GitStatus_Job.class) as GitStatus_Job
		if (!checkoutStatus)
			return null

		GitStatus_Repo repoStatus = checkoutStatus[repo.getUrl()]
		if (!repoStatus)
			return null

		return repoStatus[repo.config.branch]
	}
}

