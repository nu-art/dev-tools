package com.nu.art.pipeline.workflow.logs

import com.nu.art.belog.LoggerClient
import com.nu.art.belog.consts.LogLevel
import com.nu.art.core.tools.ExceptionTools
import com.nu.art.pipeline.workflow.Workflow

@Grab('com.nu-art-software:belog:1.2.34')

class WorkflowLogger
  extends LoggerClient<Config_WorkflowLogger> {
  private String[] LogColors = [ANSI_Colors.NoColor, ANSI_Colors.BBlue, ANSI_Colors.BGreen, ANSI_Colors.BYellow, ANSI_Colors.BRed,]

  @NonCPS
  @Override
  protected void log(long timestamp, LogLevel level, Thread thread, String tag, String message, Throwable t) {
    GString preLog = "${LogColors[level.ordinal()]}${level.name().substring(0, 1)} - ${tag}:"

    Workflow.workflow.log "${preLog} ${message}${ANSI_Colors.NoColor}"
    if (t != null) {
      Workflow.workflow.log "${preLog} ${ExceptionTools.getStackTrace(t)}${ANSI_Colors.NoColor}"
    }
  }
}