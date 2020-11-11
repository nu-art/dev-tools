package com.nu.art.pipeline.modules.git

class GitCheckoutStatus {
	String commitId

	GitCheckoutStatus() {
	}

	GitCheckoutStatus(String commitId) {
		this.commitId = commitId
	}
}
