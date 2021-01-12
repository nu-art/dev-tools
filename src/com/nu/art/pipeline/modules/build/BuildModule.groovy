package com.nu.art.pipeline.modules.build

import com.cloudbees.groovy.cps.NonCPS
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.VarConsts
import hudson.model.Cause
import hudson.model.Run
import hudson.tasks.test.AbstractTestResultAction
import org.jenkinsci.plugins.pipeline.utility.steps.fs.FileWrapper
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

class BuildModule
	extends WorkflowModule {

	TriggerCause[] triggers

	@Override
	void _init() {
		Run build = workflow.getCurrentBuild().rawBuild
		List<Cause> causes = build.getCauses()
		triggers = causes.collect { new TriggerCause(it) }
		triggers.each {
			if (it.type == TriggerCause.Type_Unknown)
				logWarning("Missing case: ${it.print()}")
			else
				logInfo("${it.print()}")
		}
	}

	TriggerCause[] getTriggerCause(String causeType) {
		return triggers.findAll { it.type == causeType }
	}

	boolean getUser() {
		if (userCause != null)
			return userCause.userName

		if (scmCause != null)
			if (scmCause.getClass().getSimpleName() == "GitHubPushCause")
				return scmUser = scmCause.pushedBy

		return "UNKNOWN"
	}

	boolean getscm() {
		scmCause.getShortDescription()
		return scmCause != null

	}

	void setDisplayName(String displayName) {
		logInfo("Setting display name: ${displayName}")
		workflow.getCurrentBuild().displayName = displayName
	}

	String getDisplayName() {
		return workflow.getCurrentBuild().displayName
	}

	void setDescription(String description) {
		logInfo("Setting description: ${description}")
		workflow.getCurrentBuild().description = description
	}

	String getDescription() {
		return workflow.getCurrentBuild().description
	}

	void setResult(String result) {
		workflow.getCurrentBuild().result = result
	}

	String getResult() {
		return workflow.getCurrentBuild().result
	}

	String getCurrentResult() {
		return workflow.getCurrentBuild().currentResult
	}

	String getDurationAsString() {
		return workflow.getCurrentBuild().durationString.replaceAll("and counting", "")
	}


	String collectDetails() {
		String displayName = getDisplayName() ? "\ndisplayName: ${getDisplayName()}" : ""
		String description = getDescription() ? "\ndescription: ${getDescription()}" : ""
		String currentResult = getCurrentResult() ? "\ncurrentResult: ${getCurrentResult()}" : ""

		return displayName + description + currentResult + result
	}

	@NonCPS
	String getTestStatuses() {
		AbstractTestResultAction testResultAction = workflow.getCurrentBuild().rawBuild.getAction(AbstractTestResultAction.class)
		if (testResultAction == null)
			return "Could not find tests"

		def total = testResultAction.totalCount
		def failed = testResultAction.failCount
		def skipped = testResultAction.skipCount
		def passed = total - failed - skipped

		return "Test Status:\n  Passed: *${passed}*, Failed: *${failed} ${testResultAction.failureDiffString}*, Skipped: *${skipped}*".toString()
	}

	String pathToFile(String pathToFile, RunWrapper build = null) {
		if (build == workflow.getCurrentBuild() || build == null)
			return "${VarConsts.Var_Workspace.get()}/${pathToFile}".toString()

		return "${VarConsts.Var_JenkinsHome.get()}/jobs/${VarConsts.Var_JobName.get()}/builds/${build.getNumber()}/${pathToFile}".toString()
	}

	CopyArtifacts copyArtifacts(String name, int build) {
		return new CopyArtifacts(this).job(name, build)
	}

	FileWrapper[] findFiles(String filter) {
		return workflow.script.findFiles(glob: filter)
	}

	RunWrapper getLastSuccessfulBuild() {
		workflow.getCurrentBuild().getPreviousSuccessfulBuild()
	}

	JobTrigger triggerJob(String name) {
		return new JobTrigger(workflow, name)
	}
}
