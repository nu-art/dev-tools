package com.nu.art.pipeline.workflow

import com.nu.art.core.generics.Processor

class WorkflowProcessor<T>
  implements Processor<T> {

  @NonCPS
  @Override
  void process(T t) {}
}