package com.nu.art.pipeline.thunderstorm

import com.nu.art.pipeline.modules.build.BuildModule
import com.nu.art.pipeline.processes.Pipeline_PromoteRepo
import com.nu.art.pipeline.thunderstorm.models.VersionApp
import com.nu.art.pipeline.workflow.utils.Utils
import groovy.json.JsonOutput

class Pipeline_PromoteThunderstorm
	extends Pipeline_PromoteRepo<Pipeline_PromoteThunderstorm> {

	@Override
	void saveVersion(String path, String version) {
		String pathToFile = getModule(BuildModule.class).pathToFile(path)
		String json = JsonOutput.toJson(new VersionApp(version))
		workflow.writeToFile(pathToFile, json)
	}

	@Override
	String readVersion(String path) {
		String fileContent = workflow.readFile(getModule(BuildModule.class).pathToFile(path))
		return (Utils.parseJson(fileContent) as VersionApp).version
	}
}
