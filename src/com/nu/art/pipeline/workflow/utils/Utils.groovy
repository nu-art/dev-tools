package com.nu.art.pipeline.workflow.utils


import groovy.json.JsonSlurper

class Utils {

	static String parseJson(String jsonAsString) {
		return new JsonSlurper().parseText(jsonAsString)
	}
}

