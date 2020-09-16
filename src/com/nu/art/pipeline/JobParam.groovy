package com.nu.art.pipeline

public class JobParam<T> {
  public static JobParam<String> Param_String = new JobParam<String>("StringParameterValue")
  public static JobParam<Boolean> Param_Boolean = new JobParam<Boolean>("BooleanParameterValue")

  public final String key

  JobParam(String key) {
    this.key = key
  }
}
