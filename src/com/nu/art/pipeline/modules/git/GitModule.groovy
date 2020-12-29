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

	private GitStatus_Job jobGitStatus
	private String checkoutStatusFileName = "checkout-status.json"

	@PackageScope
	GitRepo createRepo(GitRepoConfig config) {
		return new GitRepo(this, config)
	}

	GitRepoConfig create(String url) {
		return new GitRepoConfig(this, url)
	}

	void gitStatusSave(GitRepo repo) {
		if (!jobGitStatus)
			jobGitStatus = resolveStatus()

		if (!jobGitStatus)
			jobGitStatus = new GitStatus_Job()

		String commitId = repo.getCurrentCommit()
		GitStatus_Repo repoStatus = jobGitStatus.get(repo.getUrl())
		if (!repoStatus)
			jobGitStatus.put(repo.getUrl(), repoStatus = new GitStatus_Repo(repo.getUrl()))

		repoStatus.put(repo.config.branch, new GitStatus(repo.config.branch, commitId))
		jobGitStatus.put(repo.getUrl(), repoStatus)
		String pathToFile = getModule(BuildModule.class).pathToFile(checkoutStatusFileName)
		workflow.writeToFile(pathToFile, JsonOutput.toJson(jobGitStatus))
		workflow.archiveArtifacts checkoutStatusFileName
	}

	GitStatus gitStatus(GitRepo repo, RunWrapper build = null) {
		GitStatus_Job jobGitStatus = resolveStatus(build)

		if (!jobGitStatus)
			return null

		GitStatus_Repo repoStatus = jobGitStatus[repo.getUrl()]
		if (!repoStatus)
			return null

		return repoStatus[repo.config.branch]
	}

	private GitStatus_Job resolveStatus(RunWrapper build = null) {
		try {
			if (build == null)
				build = getModule(BuildModule.class).getLastSuccessfulBuild()

			if (build == null)
				return null

			getModule(BuildModule.class)
				.copyArtifacts(VarConsts.Var_JobName.get(), build.getNumber())
				.filter(checkoutStatusFileName)
				.output(".input")
				.copy()

			String pathToFile = ".input/${checkoutStatusFileName}"
			if (!workflow.fileExists(pathToFile))
				return null

			String fileContent = workflow.readFile(pathToFile)
			GitStatus_Job toRet = Utils.parse(fileContent, { jobInstance ->
				GitStatus_Job badJobInstance = jobInstance as GitStatus_Job
				GitStatus_Job goodJobInstance = [:]
				badJobInstance.each { k1, repoInstance ->
					GitStatus_Repo badRepoInstance = repoInstance as GitStatus_Repo
					GitStatus_Repo goodRepoInstance = [:]
					badRepoInstance.each { k2, v -> goodRepoInstance.put(k2, v as GitStatus) }
					goodJobInstance.put(k1, goodRepoInstance)
				}
				return goodJobInstance
			})
			toRet
		} catch (e) {
			logError("Failed to resolve checkout status file from previous successful .build", e)
		}
	}
}

