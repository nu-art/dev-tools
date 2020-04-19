#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/sh bash

COLOR_PREFIX="\033"
# Reset
NoColor="${COLOR_PREFIX}[0m"        # Text Reset

# Regular Colors
Black="${COLOR_PREFIX}[0;30m"       # Black
Red="${COLOR_PREFIX}[0;31m"         # Red
Green="${COLOR_PREFIX}[0;32m"       # Green
Yellow="${COLOR_PREFIX}[0;33m"      # Yellow
Blue="${COLOR_PREFIX}[0;34m"        # Blue
Purple="${COLOR_PREFIX}[0;35m"      # Purple
Cyan="${COLOR_PREFIX}[0;36m"        # Cyan
White="${COLOR_PREFIX}[0;37m"       # White
Gray="\e[37m"                       # White

# Bold
BBlack="${COLOR_PREFIX}[1;30m"      # Black
BRed="${COLOR_PREFIX}[1;31m"        # Red
BGreen="${COLOR_PREFIX}[1;32m"      # Green
BYellow="${COLOR_PREFIX}[1;33m"     # Yellow
BBlue="${COLOR_PREFIX}[1;34m"       # Blue
BPurple="${COLOR_PREFIX}[1;35m"     # Purple
BCyan="${COLOR_PREFIX}[1;36m"       # Cyan
BWhite="${COLOR_PREFIX}[1;37m"      # White

# Underline
UBlack="${COLOR_PREFIX}[4;30m"      # Black
URed="${COLOR_PREFIX}[4;31m"        # Red
UGreen="${COLOR_PREFIX}[4;32m"      # Green
UYellow="${COLOR_PREFIX}[4;33m"     # Yellow
UBlue="${COLOR_PREFIX}[4;34m"       # Blue
UPurple="${COLOR_PREFIX}[4;35m"     # Purple
UCyan="${COLOR_PREFIX}[4;36m"       # Cyan
UWhite="${COLOR_PREFIX}[4;37m"      # White

# Background
On_Black="${COLOR_PREFIX}[40m"      # Black
On_Red="${COLOR_PREFIX}[41m"        # Red
On_Green="${COLOR_PREFIX}[42m"      # Green
On_Yellow="${COLOR_PREFIX}[43m"     # Yellow
On_Blue="${COLOR_PREFIX}[44m"       # Blue
On_Purple="${COLOR_PREFIX}[45m"     # Purple
On_Cyan="${COLOR_PREFIX}[46m"       # Cyan
On_White="${COLOR_PREFIX}[47m"      # White

# High Intensity
IBlack="${COLOR_PREFIX}[0;90m"      # Black
IRed="${COLOR_PREFIX}[0;91m"        # Red
IGreen="${COLOR_PREFIX}[0;92m"      # Green
IYellow="${COLOR_PREFIX}[0;93m"     # Yellow
IBlue="${COLOR_PREFIX}[0;94m"       # Blue
IPurple="${COLOR_PREFIX}[0;95m"     # Purple
ICyan="${COLOR_PREFIX}[0;96m"       # Cyan
IWhite="${COLOR_PREFIX}[0;97m"      # White

# Bold High Intensity
BIBlack="${COLOR_PREFIX}[1;90m"     # Black
BIRed="${COLOR_PREFIX}[1;91m"       # Red
BIGreen="${COLOR_PREFIX}[1;92m"     # Green
BIYellow="${COLOR_PREFIX}[1;93m"    # Yellow
BIBlue="${COLOR_PREFIX}[1;94m"      # Blue
BIPurple="${COLOR_PREFIX}[1;95m"    # Purple
BICyan="${COLOR_PREFIX}[1;96m"      # Cyan
BIWhite="${COLOR_PREFIX}[1;97m"     # White

# High Intensity backgrounds
On_IBlack="${COLOR_PREFIX}[0;100m"  # Black
On_IRed="${COLOR_PREFIX}[0;101m"    # Red
On_IGreen="${COLOR_PREFIX}[0;102m"  # Green
On_IYellow="${COLOR_PREFIX}[0;103m" # Yellow
On_IBlue="${COLOR_PREFIX}[0;104m"   # Blue
On_IPurple="${COLOR_PREFIX}[0;105m" # Purple
On_ICyan="${COLOR_PREFIX}[0;106m"   # Cyan
On_IWhite="${COLOR_PREFIX}[0;107m"  # White
