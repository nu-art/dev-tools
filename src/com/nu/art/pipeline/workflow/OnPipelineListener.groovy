package com.nu.art.pipeline.workflow

interface OnPipelineListener {
	void onPipelineStarted()

	void onPipelineAborted()

	void onPipelineFailed(Throwable e)

	void onPipelineSuccess()
}