package com.nu.art.pipeline.modules

import com.nu.art.pipeline.workflow.WorkflowModule
import hudson.tasks.test.AbstractTestResultAction

class BuildModule
	extends WorkflowModule {

	void setDisplayName(String displayName) {
		logInfo("Setting display name: ${displayName}")
		workflow.script.currentBuild.displayName = displayName
	}

	String getDisplayName() {
		return workflow.script.currentBuild.displayName
	}

	void setDescription(String description) {
		logInfo("Setting description: ${description}")
		workflow.script.currentBuild.description = description
	}

	String getDescription() {
		return workflow.script.currentBuild.description
	}

	void setResult(String result) {
		workflow.script.currentBuild.result = result
	}

	String getResult() {
		return workflow.script.currentBuild.result
	}

	String getCurrentResult() {
		return workflow.script.currentBuild.currentResult
	}

	String getDurationAsString() {
		return workflow.script.currentBuild.durationString.replaceAll("and counting", "")
	}

	@NonCPS
	String getTestStatuses() {
		AbstractTestResultAction testResultAction = workflow.script.currentBuild.rawBuild.getAction(AbstractTestResultAction.class)
		if (testResultAction == null)
			return "Could not find tests"

		def total = testResultAction.totalCount
		def failed = testResultAction.failCount
		def skipped = testResultAction.skipCount
		def passed = total - failed - skipped

		return "Test Status:\n  Passed: *${passed}*, Failed: *${failed} ${testResultAction.failureDiffString}*, Skipped: *${skipped}*".toString()
	}
}
