package com.nu.art.pipeline.workflow.logs

import com.nu.art.belog.BeConfig

class Config_WorkflowLogger extends BeConfig.LoggerConfig {
  static final String KEY = WorkflowLogger.class.getSimpleName()

  Config_WorkflowLogger() {
    super(KEY)
    setKey("default")
  }
}
