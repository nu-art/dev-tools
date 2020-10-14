package com.nu.art.pipeline.workflow
@Grab('com.nu-art-software:module-manager:1.2.34')

import com.nu.art.modular.core.Module

abstract class WorkflowModule
  extends Module {

  protected final Workflow workflow = Workflow.workflow

  @NonCPS
  @Override
  protected void init() {}

  protected void cd(String path, Closure closure) {
    workflow.cd(path, closure)
  }

  void sh(String command) {
    workflow.sh(command)
  }

  void sh(GString command) {
    workflow.sh(command.toString())
  }
}
