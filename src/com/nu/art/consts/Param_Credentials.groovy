package com.nu.art.consts

import com.nu.art.pipeline.BasePipeline

class Param_Credentials
  extends Param_EnvVar {

  final String type
  final String jenkinsCredentialId

  Param_Credentials(String envVarName, String type, String jenkinsCredentialId) {
    super(envVarName)
    this.type = type
    this.jenkinsCredentialId = jenkinsCredentialId
  }

  Object cred() {
    return BasePipeline.instance.script."$type"(credentialsId: jenkinsCredentialId, variable: envVarName)
  }
}