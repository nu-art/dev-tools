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

	public setWebAppUrl(String webAppUrl) {
		this.webAppUrl = webAppUrl
		return this
	}

	public setFirebaseProjectUrl(String firebaseProjectUrl) {
		this.firebaseProjectUrl = firebaseProjectUrl
		return this
	}
}
