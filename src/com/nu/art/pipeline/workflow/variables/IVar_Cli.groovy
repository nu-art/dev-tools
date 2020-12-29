package com.nu.art.pipeline.workflow.variables

import com.nu.art.pipeline.interfaces.Getter


interface IVar_Cli
  extends Getter<String> {

  String key()
}