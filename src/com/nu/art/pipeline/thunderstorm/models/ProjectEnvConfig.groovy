package com.nu.art.pipeline.thunderstorm.models

class ProjectEnvConfig {
	String webAppUrl
	String firebaseProjectUrl

	ProjectEnvConfig(String projectId) {
		this.webAppUrl = "https://${projectId}.firebaseapp.com"
		this.firebaseProjectUrl = "https://console.firebase.google.com/project/${projectId}"
	}

	ProjectEnvConfig(String webAppUrl, String firebaseProjectUrl) {
		this.webAppUrl = webAppUrl
		this.firebaseProjectUrl = firebaseProjectUrl
	}
}
