package com.nu.art.consts

class Param_CLI_Value
  extends Param_CLI {

  final Closure<String> value

  Param_CLI_Value(String envVar, String cliParamName, Closure<String> value) {
    super(envVar, cliParamName)
    this.value = value
  }

  String envValue() {
    return value.call()
  }
}