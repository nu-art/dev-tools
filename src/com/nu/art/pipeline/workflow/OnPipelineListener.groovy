package com.nu.art.pipeline.workflow

interface OnPipelineListener {
	void onPipelineStarted()

	void onPipelineFailed(Throwable e)

	void onPipelineSuccess()
}