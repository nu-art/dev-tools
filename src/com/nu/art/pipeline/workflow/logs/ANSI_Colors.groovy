package com.nu.art.pipeline.workflow.logs;

class ANSI_Colors {

  static String COLOR_PREFIX = "\033"
  static String NoColor = "${COLOR_PREFIX}[0m".toString()        // Text Reset
  static String BBlack = "${COLOR_PREFIX}[1;30m".toString()     // Black
  static String BRed = "${COLOR_PREFIX}[1;31m".toString()       // Red
  static String BGreen = "${COLOR_PREFIX}[1;32m".toString()     // Green
  static String BYellow = "${COLOR_PREFIX}[1;33m".toString()    // Yellow
  static String BBlue = "${COLOR_PREFIX}[1;34m".toString()      // Blue
  static String BPurple = "${COLOR_PREFIX}[1;35m".toString()    // Purple
  static String BCyan = "${COLOR_PREFIX}[1;36m".toString()      // Cyan
  static String BWhite = "${COLOR_PREFIX}[1;37m".toString()     // White
}

