export PATH=/opt/homebrew/bin:$PATH
export githubUserName=${YOUR_GITHUB_USER_NAME_HERE}

alias lbd='npm run serve-debug'
alias lf='npm run dev'
alias lb='npm run serve'
alias kn='killall 9 node'
alias kj='killall 9 java'

alias bai-test='bash build-and-install.sh --debug --test-mode'
alias bait-test='bash build-and-install.sh --debug --test-mode --no-som'
alias bais-test='bash build-and-install.sh --debug --test-mode --no-tablet'

alias baia='bash build-and-install.sh --debug --agent-only'
alias bait='bash build-and-install.sh --debug --no-som'
alias bais='bash build-and-install.sh --debug --no-tablet'

# Typescript Boilerplate
alias deploy-test='bash build-and-install.sh -se=test --setup -df -db'
alias deploy-staging='bash build-and-install.sh -se=staging --setup -df -db'
alias deploy-prod='bash build-and-install.sh -se=prod --setup -df -db'

alias bai='baiImpl'
function baiImpl() {
  if [[ -e build-and-install.sh ]]; then
    bash build-and-install.sh ${@} --debug
    return
  fi

  local runningFolder=$(pwd | sed -E "s/.*\/(.*)$/\1/g")
  cd ..
  trap "echo BREAK" SIGINT
    bash build-and-install.sh "${@}" -up=${runningFolder} --debug
  trap - SIGINT
  cd ${runningFolder}
}

# Git Scripts
function gitcommitpush() {
        git add . && git commit -am "$1" && git push
}

function updateSubmoduleToLatest() {
  local repo=$1
  local branch=${2-master}

  if [[ ! "${repo}" ]]; then
    echo "need to specify submodule repo name"
    return
  fi

  cd ${repo}
    git checkout ${branch}
    git pull
  cd ..
}

alias grh='git reset --hard'
alias gc='git checkout'
alias gm='git merge'
alias gmo='git merge origin/'
alias gcm='git commit -am '
alias gcp='gitcommitpush '
alias _gsu='updateSubmoduleToLatest'

alias gs='git status'
alias gsu='git submodule update'
alias gsui='git submodule update --init'
alias gsf='git submodule foreach'

alias _udt='cd dev-tools && git checkout master && git pull && cd ..'

alias _align='bash ./dev-tools/scripts/dev/align-branch.sh --debug'
alias _reset='bash ./dev-tools/scripts/git/git-reset.sh --debug'

alias _status='bash ./dev-tools/scripts/git/git-status.sh --debug'
alias _pull='bash ./dev-tools/scripts/git/git-pull.sh --debug --project'
alias _checkout='bash ./dev-tools/scripts/git/git-checkout.sh --debug --project'
alias _push='bash ./dev-tools/scripts/git/git-push.sh --debug'
alias _merge='bash ./dev-tools/scripts/git/git-merge.sh --debug'
alias _prune='bash ./dev-tools/scripts/git/git-prune.sh'
alias _request-pull='bash ./dev-tools/scripts/git/git-pull-request.sh --debug --github-username=${githubUserName}'