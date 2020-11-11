package com.nu.art.pipeline.workflow.utils


import groovy.json.JsonSlurper

class Utils {

	static String parseJson(String jsonAsString) {
		return new JsonSlurper().parseText(jsonAsString)
	}

	static <T> T parse(String jsonAsString, Class<T> type) {
		return new JsonSlurper().parseText(jsonAsString) as T
	}
}

