package com.nu.art.pipeline.modules

import com.nu.art.pipeline.workflow.OnPipelineListener
import com.nu.art.pipeline.workflow.WorkflowModule
import com.nu.art.pipeline.workflow.variables.Consts
import com.nu.art.pipeline.workflow.variables.Var_Creds
import com.nu.art.utils.Colors

class SlackModule
	extends WorkflowModule
	implements OnPipelineListener {

	private Var_Creds SlackToken
	private String defaultChannel
	private BuildModule buildModule

	void prepare() {
		setTokenCredentialsId("slack-token")
		buildModule = getModule(BuildModule.class)
	}

	void setTokenCredentialsId(String tokenCredentialId) {
		SlackToken = new Var_Creds("string", tokenCredentialId)
	}

	void setDefaultChannel(String defaultChannel) {
		this.defaultChannel = defaultChannel
	}

	void notify(GString message, String color, String channelName = defaultChannel) {
		notify(message.toString(), color, channelName)
	}

	void notify(String message, String color, String channelName = defaultChannel) {
		String preMessage = "*${Consts.Var_JobName.get()}* - #${Consts.Var_BuildNumber.get()} (<${Consts.Var_BuildUrl.get()}|Open>)\n"
		String finalMessage = "${preMessage}\n${message}"
		workflow.script.slackSend(color: color, channel: channelName, message: finalMessage, tokenCredentialId: SlackToken.id)
	}

	@Override
	void onPipelineStarted() {
		notify("Started - ${buildModule.getDisplayName()}", Colors.Gray)
	}

	@Override
	void onPipelineFailed(Throwable e) {
		String description = buildModule.getDescription() ? "\n${buildModule.getDescription()}" : ""
		notify("Error - ${buildModule.getDisplayName()}${description}", Colors.Red)
	}

	@Override
	void onPipelineSuccess() {
		String description = buildModule.getDescription() ? "\n${buildModule.getDescription()}" : ""
		notify("Success - ${buildModule.getDisplayName()}${description}", Colors.Green)
	}

}
