package com.nu.art.pipeline.modules.gcpBucket


import com.nu.art.pipeline.workflow.WorkflowModule

class GCP_BucketModule
	extends WorkflowModule {


	@Override
	void _init() {
		// TODO check if gsutils is installed
		// TODO check that google credentials exist
		// ...

	}

	copyArtifactToBucket(String localPath, String bucketPath) {
		workflow.sh "gsutil cp ${localPath} gs://${env.GCS_BUCKET}/${bucketPath}"
	}

}
