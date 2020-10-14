package com.nu.art.pipeline.thunderstorm

class Pipeline_ThunderstormWebApp
  extends Pipeline_ThunderstormCore {

  private String env
  private String fallEnv

  Pipeline_ThunderstormWebApp(def script, String name) {
    super(script, name)
  }

  void setEnv(String env, String fallEnv = "") {
    this.env = env
    this.fallEnv = fallEnv
  }

  void deploy(Closure postDeploy) {
    addStage("deploy", { this._deploy() })
    if (postDeploy)
      addStage("post-deploy", { postDeploy() })
  }

  protected void _install() {
    _sh("bash build-and-install.sh --set-env=${this.env} -fe=${this.fallEnv} --install --no-build --link")
  }

  private void _deploy() {
    _sh("bash build-and-install.sh --deploy --quick-deploy --no-git")
  }
}
