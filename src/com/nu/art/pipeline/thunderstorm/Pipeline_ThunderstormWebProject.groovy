package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.modules.SlackModule
import com.nu.art.pipeline.modules.docker.DockerModule
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.thunderstorm.Pipeline_ThunderstormWebApp
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Var_Creds
import com.nu.art.pipeline.workflow.variables.Var_Env

class Pipeline_ThunderstormWebProject<T extends Pipeline_ThunderstormWebProject>
	extends Pipeline_ThunderstormWebApp<T> {

	public Var_Env Env_Branch = new Var_Env("BRANCH_NAME")

	String httpUrl
	String gitRepoUri
	def envProjects = [:]

	Pipeline_ThunderstormWebProject(String name, String slackChannel, Class<? extends WorkflowModule>... modules) {
		super(name, modules)
	}

	@Override
	protected void init() {
		String branch = Env_Branch.get()
		getModule(SlackModule.class).prepare()
		getModule(SlackModule.class).setDefaultChannel("backend")

		setRepo(getModule(GitModule.class)
			.create(gitRepoUri)
			.setBranch(branch)
			.build())

		String links = ("" +
			"<https://${envProjects.get(branch)}.firebaseapp.com|WebApp> | " +
			"<https://console.firebase.google.com/project/${envProjects.get(branch)}|Firebase> | " +
			"<${this.httpUrl}|Github>").toString()

		getModule(SlackModule.class).setOnSuccess(links)

		setEnv(branch)
		switch (branch) {
			case "dev":
				setEnv("dev-server", branch)
				break
		}
	}

	void setGitRepoId(String repoId) {
		this.httpUrl = "https://github.com/${repoId}".toString()
		this.gitRepoUri = "git@github.com:${repoId}.git".toString()
	}

	void declareEnv(String env, String projectId) {
		envProjects.put(env, projectId)
	}

	@Override
	void pipeline() {
		String branch = Env_Branch.get()

		checkout({
			getModule(SlackModule.class).setOnSuccess(getRepo().getChangeLog().toSlackMessage())
		})
		install()
		build()
//		test()

		deploy()
//		run("register", {
//			String registerURL = "https://us-central1-${envProjects.get(branch)}.cloudfunctions.net/api/v1/register/register-project"
//			workflow.sh """curl -H "x-secret: ${Env_RegisterToken.get()}" -H "x-proxy: jenkins" ${registerURL}"""
//		})
	}
}
