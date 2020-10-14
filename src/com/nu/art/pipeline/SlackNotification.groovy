package com.nu.art.pipeline

import com.nu.art.consts.Param_Credentials
import com.nu.art.consts.Param_EnvVar

class SlackNotification {
  public static Param_Credentials SlackToken = new Param_Credentials("SLACK_TOKEN", "string", "slack-token")
  private String channel

  SlackNotification(String channel) {
    this.channel = channel
  }

  void notify(String message, String color, String channelName = channel) {
    String preMessage = "*${Param_EnvVar.JobName.envValue()}* - #${Param_EnvVar.BuildNumber.envValue()} (<${Param_EnvVar.BuildUrl.envValue()}|Open>)\n"
    String finalMessage = "${preMessage}\n${message}"
    BasePipeline.instance.script.slackSend(color: color, channel: channelName, message: finalMessage, tokenCredentialId: SlackToken.jenkinsCredentialId)
  }
}
