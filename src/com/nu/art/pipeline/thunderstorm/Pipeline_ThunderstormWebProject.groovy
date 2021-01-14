package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.modules.SlackModule
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Var_Env

class Pipeline_ThunderstormWebProject<T extends Pipeline_ThunderstormWebProject>
	extends Pipeline_ThunderstormWebApp<T> {

	public Var_Env Env_Branch = new Var_Env("BRANCH_NAME")

	String httpUrl
	String gitRepoUri
	def envProjects = [:]
	String slackChannel
	boolean scm

	Pipeline_ThunderstormWebProject(String name, String slackChannel, Class<? extends WorkflowModule>... modules) {
		super(name, modules)
		this.slackChannel = slackChannel
	}

	@Override
	protected void init() {
		String branch = Env_Branch.get()
		getModule(SlackModule.class).setDefaultChannel(this.slackChannel)

		setRepo(getModule(GitModule.class)
			.create(gitRepoUri)
			.setTrackSCM(scm)
			.setBranch(branch)
			.build())

		String links = ("" +
			"<https://${envProjects.get(branch)}.firebaseapp.com|WebApp> | " +
			"<https://console.firebase.google.com/project/${envProjects.get(branch)}|Firebase> | " +
			"<${this.httpUrl}|Github>").toString()

		getModule(SlackModule.class).setOnSuccess(links)

		setEnv(branch)
		super.init()
	}

	void setGitRepoId(String repoId, boolean scm = false) {
		this.httpUrl = "https://github.com/${repoId}".toString()
		this.gitRepoUri = "git@github.com:${repoId}.git".toString()
		this.scm = scm
	}

	void declareEnv(String env, String projectId) {
		envProjects.put(env, projectId)
	}

	@Override
	void pipeline() {
		checkout({
			getModule(SlackModule.class).setOnSuccess(getRepo().getChangeLog().toSlackMessage())
		})

		install()
		clean()
		build()
//		test()

		deploy()
	}
}
