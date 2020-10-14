package com.nu.art.consts

import com.nu.art.pipeline.BasePipeline

class Param_EnvVar {

  public static Param_EnvVar JobName = new Param_EnvVar("JOB_NAME")
  public static Param_EnvVar BuildUrl = new Param_EnvVar("BUILD_URL")
  public static Param_EnvVar BuildNumber = new Param_EnvVar("BUILD_NUMBER")
  public static Param_EnvVar BranchName = new Param_EnvVar("BRANCH_NAME")
  public static Param_EnvVar Workspace = new Param_EnvVar("WORKSPACE")
  public static Param_EnvVar ServiceAccount = new Param_EnvVar("SERVICE_ACCOUNT")

  final String envVarName

  Param_EnvVar(String envVarName) {
    this.envVarName = envVarName
  }

  String envValue() {
    return BasePipeline.instance.getEnv(envVarName)
  }
}