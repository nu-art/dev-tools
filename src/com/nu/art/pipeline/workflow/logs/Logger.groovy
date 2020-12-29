package com.nu.art.pipeline.workflow.logs

import com.nu.art.belog.consts.LogLevel
import com.nu.art.core.tools.ArrayTools
import com.nu.art.core.tools.ExceptionTools

import static com.nu.art.belog.consts.LogLevel.*

/**
 * Created by TacB0sS on 27-Feb 2017.
 */

class Logger {


  private String tag

  private boolean enable = true

  private LogLevel minLogLevel = Verbose

  protected Logger() {
    String fqn = getClass().getName()
    tag = fqn.substring(fqn.lastIndexOf(".") + 1)
  }

  void setTag(String tag) {
    this.tag = tag
  }

  String getTag() {
    return tag
  }

  void setMinLogLevel(LogLevel minLogLevel) {
    this.minLogLevel = minLogLevel
  }

  private boolean canLog(LogLevel logLevelToLog) {
    return logLevelToLog.ordinal() >= minLogLevel.ordinal() && isLoggerEnabled()
  }

  void setLoggerEnable(boolean enable) {
    this.enable = enable
  }

  protected boolean isLoggerEnabled() {
    return enable
  }

  void log(LogLevel level, String message) {
    finalLog(level, message)
  }

  void log(LogLevel level, Throwable e) {
    finalLog(level, null, e)
  }

  void log(LogLevel level, String message, Throwable e) {
    finalLog(level, message, e)
  }

  void log(LogLevel level, String message, Object... params) {
    finalLog(level, message, params)
  }

  private void finalLog(LogLevel level, String message, Object... params) {
    if (!canLog(level))
      return

    Throwable t = null
    Object lastParam = null
    if (params.length > 0) {
      lastParam = params[params.length - 1]
      if (lastParam instanceof Throwable)
        t = (Throwable) lastParam
    }

    try {
      logImpl(level, tag, message, params, t)
    } catch (Exception e) {
      if (lastParam == t && t != null)
        try {
          logImpl(level, tag, message, ArrayTools.removeElement(params, t), t)
          e = null
        } catch (Exception e1) {
          e = e1
        }

      if (e != null)
        logImpl(LogLevel.Error, tag, "Error formatting string: " + message + ", with params: " + ArrayTools.printGenericArray("", -1, params), null, e)
    }
  }

  private void logImpl(LogLevel logLevel, String tag, String message, Object[] params, Throwable throwable) {
    GString preLog = "${LogColors[logLevel.ordinal()]}${LogLevel.name().substring(0, 1)} - ${tag}:"
    if (message)
      System.out.println("${preLog} ${String.format(message, params)}".toString())

    if (throwable) {
      System.out.println("${preLog} ${throwable.getMessage()}".toString())
      System.out.println("${preLog} ${ExceptionTools.getStackTrace()}".toString())
    }
  }

  /*
   * VERBOSE
   */

  void logVerbose(String verbose) {
    log(Verbose, verbose)
  }

  void logVerbose(String verbose, Object... params) {
    log(Verbose, verbose, params)
  }

  void logVerbose(Throwable e) {
    log(Verbose, e)
  }

  void logVerbose(String verbose, Throwable e) {
    log(Verbose, verbose, e)
  }

  /*
   * DEBUG
   */

  void logDebug(String debug) {
    log(Debug, debug)
  }

  void logDebug(String debug, Object... params) {
    log(Debug, debug, params)
  }

  void logDebug(Throwable e) {
    log(Debug, e)
  }

  void logDebug(String debug, Throwable e) {
    log(Debug, debug, e)
  }

  /*
   * INFO
   */

  void logInfo(String info) {
    log(Info, info)
  }

  void logInfo(String info, Object... params) {
    log(Info, info, params)
  }

  void logInfo(Throwable e) {
    log(Info, e)
  }

  void logInfo(String info, Throwable e) {
    log(Info, info, e)
  }

  /*
   * WARNING
   */

  void logWarning(String warning) {
    log(Warning, warning)
  }

  void logWarning(String warning, Object... params) {
    log(Warning, warning, params)
  }

  void logWarning(Throwable e) {
    log(Warning, e)
  }

  void logWarning(String warning, Throwable e) {
    log(Warning, warning, e)
  }

  /*
   * ERROR
   */

  void logError(String error) {
    log(Error, error)
  }

  void logError(String error, Object... params) {
    log(Error, error, params)
  }

  void logError(Throwable e) {
    log(Error, e)
  }

  void logError(String error, Throwable e) {
    log(Error, error, e)
  }

}
