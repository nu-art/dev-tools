/*
 * Permissions management system, define access level for each of
 * your server apis, and restrict users by giving them access levels
 *
 * Copyright (C) 2020 Adam van der Kruk aka TacB0sS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.nu.art.pipeline.workflow

import com.nu.art.pipeline.modules.SlackModule
import com.nu.art.pipeline.modules.build.BuildModule
import com.nu.art.pipeline.modules.build.JobTrigger
import com.nu.art.pipeline.workflow.variables.VarConsts
import com.nu.art.pipeline.workflow.variables.Var_Env

abstract class Pipeline_BaseProxy<T extends Pipeline_BaseProxy>
	extends BasePipeline<T> {

	public Var_Env Env_Branch = new Var_Env("BRANCH_NAME")
	def envJobs = [:]

	Pipeline_BaseProxy() {
		super("proxy", ([SlackModule.class] as Class<? extends WorkflowModule>[]) as Class<? extends WorkflowModule>[])
	}

	Pipeline_BaseProxy(Class<? extends WorkflowModule>... modules) {
		super("proxy", (([SlackModule.class] as Class<? extends WorkflowModule>[]) + modules) as Class<? extends WorkflowModule>[])
	}

	Pipeline_BaseProxy(String name) {
		super(name, (([SlackModule.class] as Class<? extends WorkflowModule>[])) as Class<? extends WorkflowModule>[])
	}

	Pipeline_BaseProxy(String name, Class<? extends WorkflowModule>... modules) {
		super(name, (([SlackModule.class] as Class<? extends WorkflowModule>[]) + modules) as Class<? extends WorkflowModule>[])
	}

	void declareJob(String branch, String jobName) {
		envJobs.put(branch, jobName)
	}

	void setDisplayName() {
		def branch = Env_Branch.get()
		getModule(BuildModule.class).setDisplayName("#${VarConsts.Var_BuildNumber.get()}: ${getName()}-${branch}")
	}

	@Override
	void pipeline() {
		addStage("running", {
			def branch = Env_Branch.get()
			def jobName = (String) envJobs[branch]
			new JobTrigger(workflow, jobName).setWait(false).run()
		})
	}
}
