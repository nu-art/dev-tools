projectName="thunderstorm"
source ${BASH_SOURCE%/*}/../../_core-tools/_source.sh
source ${BASH_SOURCE%/*}/params.sh

extractParams "$@"

if [[ ! -e "${projectName}" ]]; then
  git clone "${gitUrl}" --recursive --branch "${branch}" "${folderName}"
  throwError "Error cloning repo"
else
  _cd "${folderName}"
  git pull
  throwError "Error pulling repo"
  _cd..
fi

_cd "${folderName}"
bash ./dev-tools/scripts/git/git-reset.sh -a
bash ./dev-tools/scripts/git/git-checkout.sh --branch=${branch} --all
bash ./dev-tools/scripts/git/git-pull.sh -a -f

[[ "${publish}" ]] && publish="--publish=${promoteVersion}"
[[ "${deploy}" ]] && version="--set-version=$(getVersionName version-app.json).${BUILD_NUMBER}"
[[ "${deploy}" ]] && deploy="-d"
bash build-and-install.sh --debug -i -c "-se=${environment}" --account=/etc/test-account.json --log=verbose "${publish}" ${deploy} ${version}
throwError "Error while publishing artifacts to NPM and deploying project"

newVersionName=$(getVersionName version-thunderstorm.json)
echo newVersionName="${newVersionName}" > ../build.properties

errorMessage=$(cat ./error_message.txt)
echo errorMessage="${errorMessage}" >> ../build.properties
_cd..
