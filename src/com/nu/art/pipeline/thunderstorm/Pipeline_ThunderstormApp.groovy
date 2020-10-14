package com.nu.art.pipeline.thunderstorm

class Pipeline_ThunderstormApp<T extends Pipeline_ThunderstormApp>
	extends Pipeline_ThunderstormCore<T> {

	Pipeline_ThunderstormApp(GString name) {
		this(name.toString())
	}

	Pipeline_ThunderstormApp(String name) {
		super(name)
	}

	Pipeline_ThunderstormApp() {
		super()
	}

	void preparePipeline() {
		checkout()
		install()
	}

	void pipeline() {
		preparePipeline()
	}
}