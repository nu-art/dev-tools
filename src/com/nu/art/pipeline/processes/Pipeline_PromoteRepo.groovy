package com.nu.art.pipeline.processes

import com.nu.art.pipeline.exceptions.BadImplementationException
import com.nu.art.pipeline.modules.git.GitCli
import com.nu.art.pipeline.modules.git.GitModule
import com.nu.art.pipeline.modules.git.GitRepo
import com.nu.art.pipeline.workflow.BasePipeline
import com.nu.art.pipeline.workflow.variables.Var_Env

abstract class Pipeline_PromoteRepo<T extends Pipeline_PromoteRepo>
        extends BasePipeline<T> {

    public Var_Env Env_RepoUrl = new Var_Env("REPO_URL")
    public Var_Env Env_FromBranch = new Var_Env("FROM_BRANCH")
    public Var_Env Env_ToBranch = new Var_Env("TO_BRANCH")
    public Var_Env Env_AlignSubmodules = new Var_Env("ALIGN_SUBMODULES")
    public Var_Env Env_Promote = new Var_Env("PROMOTE")
    public Var_Env[] params = [
            Env_RepoUrl,
            Env_FromBranch,
            Env_ToBranch,
            Env_AlignSubmodules,
            Env_Promote
    ]

    String relativePathToVersionFile

    Pipeline_PromoteRepo() {
        this("promote", "version-app.json")
    }

    Pipeline_PromoteRepo(String name) {
        this(name, "version-app.json")
    }

    Pipeline_PromoteRepo(String name, String relativePathToVersionFile) {
        super(name, GitModule.class)
        this.relativePathToVersionFile = relativePathToVersionFile
    }

    abstract void saveVersion(String path, String version)

    abstract String readVersion(String path)

    @Override
    void pipeline() {
        printEnvParams(params)
        addStage("promote", {
            // get changes between from and to branches

            String fromBranch = Env_FromBranch.get()
            String toBranch = Env_ToBranch.get()

            GitRepo repo = getModule(GitModule.class)
                    .create(Env_RepoUrl.get())
                    .setBranch(toBranch)
                    .build()

            // define path to version-app file in repo
            String pathToVersionFile = "${repo.getOutputFolder()}/${this.relativePathToVersionFile}"

            // clone and checkout fromBranch
            GitCli
                    .create(repo)
                    .runInRepoFolder(false)
                    .clone(repo.config)
                    .checkout(fromBranch)
                    .execute()

            // read version of the fromBranch
            String beforeVersion = readVersion(pathToVersionFile)

            // merge fromBranch to the toBranch
            // push toBranch and checkout fromBranch again
            GitCli
                    .create(repo)
                    .checkout(toBranch)
                    .gsui()
                    .merge("origin/${fromBranch}")
                    .gsui()
                    .push()
                    .checkout(fromBranch)
                    .execute()

            // tag commit of both branches
            GitCli
                    .create(repo)
                    .createTag("${toBranch}-v${beforeVersion}").pushTags()
                    .execute()

            // used to decide if the branch you wish to push the code will promote the code version or not
            if (Env_Promote.get() == "none")
                return

            //iserts the output of promoteVersion
            String afterVersion = promoteVersion(beforeVersion, deriveIndexToPromote(Env_Promote))
            saveVersion(pathToVersionFile, afterVersion)

            //pushes to dev branch the new version of code using promoteVersion function
            GitCli
                    .create(repo)
                    .commit("Promoted version to: ${beforeVersion} => ${afterVersion}").push()
                    .createTag("${fromBranch}-v${afterVersion}").pushTags()
                    .execute()
        })
    }

    @SuppressWarnings('GrMethodMayBeStatic')
    def promoteVersion(String version, int index) {
        logDebug("papa ${version}, ${index}")

        if (index != 1 && index != 2) {
            throw new IllegalArgumentException("Index must be either 1 or 2..")
        }

        def versionParts = version.split("\\.")

        versionParts[index] = (versionParts[index].toInteger() + 1).toString()

        if (index == 1) {
            versionParts[2] = "0"
        }

        return versionParts.join(".")
    }





    @SuppressWarnings('GrMethodMayBeStatic')
    int deriveIndexToPromote(Var_Env var) {
        switch (var.get()) {
            case "major":
                return 0
            case "minor":
                return 1
            case "patch":
                return 2
        }
        throw new BadImplementationException("unsupported promotion type: ${var.get()}")
    }
}
