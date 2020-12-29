package com.nu.art.pipeline.workflow

import com.nu.art.modular.core.Module
import com.nu.art.modular.core.ModulesPack

abstract class WorkflowModulesPack
  extends ModulesPack {

  WorkflowModulesPack(Class<? extends Module>... moduleTypes) {
    super(moduleTypes)
  }
}
