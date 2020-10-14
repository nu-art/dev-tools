package com.nu.art.thunderstorm

import com.nu.art.pipeline.BasePipeline
import com.nu.art.utils.Colors

class Pipeline_ThunderstormCore<T extends Pipeline_ThunderstormCore>
  extends BasePipeline<T> {

  Pipeline_ThunderstormCore(def script, String name) {
    super(script, name)
  }

  T prepare(Closure _prepare) {
    super.prepare(_prepare)

    addStage("checkout", { this._checkout() })
    if (docker)
      addStage("launch-docker", { this._launchDocker() })
    return (T) this
  }

  T install() {
    addStage("install", { this._install() })
    return (T) this
  }

  T build() {
    addStage("compile", { this._compile() })
    addStage("lint", { this._lint() })
    return (T) this
  }

  T test() {
    addStage("test", { this._test() })
    return (T) this
  }

  T run(String name, Closure toRun) {
    addStage(name, { toRun() })
    return (T) this
  }

  T completed(String message = "Completed") {
    addStage("completed", {
      slack.notify(message, Colors.Green)
    })
  }

  @Override
  protected void onError(String stage, Throwable error) {
    if (docker)
      docker.kill()
  }

  protected void _checkout() {
    repo.cloneRepo()
  }

  protected void _launchDocker() {
    docker.launch()
  }

  protected void _install() {
    _sh("bash build-and-install.sh --install --no-build --link")
  }

  protected void _compile() {
    _sh("bash build-and-install.sh")
  }

  protected void _lint() {
    _sh("bash build-and-install.sh --lint --no-build")
  }

  protected void _test() {
    _sh("bash build-and-install.sh --test --no-build")
  }

  T _sh(GString command) {
    if (docker) {
      docker.sh(command)
      return (T) this
    }

    return (T) super.sh(command)
  }

  T _sh(String command) {
    if (docker) {
      docker.sh(command)
      return (T) this
    }

    return (T) super.sh(command)
  }
}