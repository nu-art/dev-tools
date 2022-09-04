package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.modules.SlackModule
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.thunderstorm.models.ProjectEnvConfig
import com.nu.art.pipeline.thunderstorm.models.ProjectGitConfig
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Var_Env

class Pipeline_ThunderstormWebProject<T extends Pipeline_ThunderstormWebProject>
	extends Pipeline_ThunderstormWebApp<T> {

	public Var_Env Env_Branch = new Var_Env("BRANCH_NAME")

	ProjectGitConfig gitConfig
	def envProjects = [:]
	String slackChannel

	Pipeline_ThunderstormWebProject(String name, String slackChannel, Class<? extends WorkflowModule>... modules) {
		super(name, modules)
		this.slackChannel = slackChannel
	}

	@Override
	protected void init() {
		String branch = Env_Branch.get()
		getModule(SlackModule.class).setDefaultChannel(this.slackChannel)


		GitModule gitModule = getModule(GitModule.class)
		setRepo(gitModule
			.create(gitConfig.gitRepoUri)
			.setTrackSCM(gitConfig.scm)
			.setBranch(branch)
			.build())


		ProjectEnvConfig envConfig = envProjects.get(branch) as ProjectEnvConfig
		String links = ("" +
			"<${envConfig.webAppUrl}|WebApp> | " +
			"<${envConfig.firebaseProjectUrl}|Firebase> | " +
			"<${gitConfig.httpUrl}|Github>").toString()

		getModule(SlackModule.class).setOnSuccess(links)

		setEnv(branch)
		super.init()
	}

	void setGitRepoId(String repoId, boolean scm = false) {
		setProjectGitConfig(new ProjectGitConfig(repoId, scm))
	}

	void setProjectGitConfig(ProjectGitConfig gitConfig) {
		this.gitConfig = gitConfig
	}

	void declareEnv(String env, String projectId) {
		declareEnv(env, new ProjectEnvConfig(projectId))
	}

	void declareEnv(String env, ProjectEnvConfig envConfig) {
		envProjects.put(env, envConfig)
	}

	@Override
	void pipeline() {
		checkout({
			getModule(SlackModule.class).setOnSuccess(getRepo().getChangeLog().toSlackMessage())
		})

		install()
		clean()
		build()
		test()

		deploy()
	}
}
