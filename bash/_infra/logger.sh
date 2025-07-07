// file: ./core/tools/logger.sh
#!/bin/bash

LOG_LEVEL__VERBOSE=0
LOG_LEVEL__DEBUG=1
LOG_LEVEL__INFO=2
LOG_LEVEL__WARNING=3
LOG_LEVEL__ERROR=4

logger_level=${LOG_LEVEL__VERBOSE}
logger_colors=("${NoColor}" "${BBlue}" "${BGreen}" "${BYellow}" "${BRed}")
logger_prefixes=("-V-" "-D-" "-I-" "-W-" "-E-")

logger_debugEnabled=
logger_debugFile=

logger.setDebugFile() {
  logger_debugFile=${1}
  logger_debugEnabled=true
  rm -f "${logger_debugFile}"
}

logger.setDebug() {
  logger_debugEnabled=${1}
}

logger.setLevel() {
  case ${1} in
    0 | 1 | 2 | 3 | 4)
      logger_level=${1}
      ;;
    *)
      log.error "Wrong log level"
      exit
      ;;
  esac
}

logger.setFile() {
  logger.setLevel "${1}"
  local relativePathToLogFolder=${2}
  local logFilePrefix=${3}

  local logsFolder="$(pwd)/${relativePathToLogFolder}"
  local dateTimeFormatted=$(date +%Y-%m-%d--%H-%M-%S)

  [[ ! -d "${logsFolder}" ]] && folder.create "${logsFolder}"

  local logger_logFile="${logsFolder}/${logFilePrefix}-log-${dateTimeFormatted}.txt"
  touch "${logger_logFile}"
}

_logger.log() {
  local level=$1
  local logMessage=$2

  local color=${logger_colors[${level}]}

  ((level < logger_level)) && return

  startTimer "log-tools"
  local duration=$(calcDuration "rootTimer")
  local logDate="(${duration}) $(date +"%Y-%m-%d_%H:%M:%S")"
  logMessage=${logMessage//$'\n'/"\n"${NoColor}${logDate} $$  ${color}}
  echo -e "${logDate} $$  ${color}${logMessage}${NoColor}"\r
}

log.verbose() { _logger.log 0 "$1"; }
log.debug()   { _logger.log 1 "$1"; }
log.info()    { _logger.log 2 "$1"; }
log.warning() { _logger.log 3 "$1"; }
log.error()   { _logger.log 4 "$1"; }

banner.verbose() { _logger.banner 0 "$1" "$2"; }
banner.debug()   { _logger.banner 1 "$1" "$2"; }
banner.info()    { _logger.banner 2 "$1" "$2"; }
banner.warning() { _logger.banner 3 "$1" "$2"; }
banner.error()   { _logger.banner 4 "$1" "$2"; }

_logger.banner() {
  local level=$1
  local logMessage=$2
  local color=$3
  local nocolor=${logger_colors[${level}]}

  local add="$(echo "$logMessage" | sed -E 's/./-/g')"
  _logger.log ${level} "+---$add---+"
  _logger.log ${level} "|   ${color}${logMessage}${nocolor}   |"
  _logger.log ${level} "+---$add---+"
}

_log.Verbose() { _logger._log log.verbose "$@"; }
_log.Debug()   { _logger._log log.debug "$@"; }
_log.Info()    { _logger._log log.info "$@"; }
_log.Warning() { _logger._log log.warning "$@"; }
_log.Error()   { _logger._log log.error "$@"; }

_logger._log() {
  [[ ! "$logger_debugEnabled" ]] && return
  [[ "$logger_debugFile" ]] && ${1} "- DEBUG - ${*:2}" >> "$logger_debugFile" && return
  ${1} "- DEBUG - ${*:2}"
}
