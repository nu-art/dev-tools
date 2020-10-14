package com.nu.art.consts

class Param_CLI
  extends Param_EnvVar {

  final String cliParamName

  Param_CLI(String envVar, String cliParamName) {
    super(envVar)
    this.cliParamName = cliParamName
  }
}