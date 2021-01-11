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

package com.nu.art.pipeline.modules.build

import hudson.model.Cause

class TriggerCause {
	public static String Type_User = "user"
	public static String Type_SCM = "scm"
	public static String Type_Rebuild = "rebuild"
	public static String Type_Unknown = "unknown"

	final String className
	final String description
	final String type
	final String originator
	final String data

	TriggerCause(Cause cause) {
		className = cause.getClass().getName()
		description = cause.getShortDescription()

		switch (className) {
			case 'hudson.model.Cause$UserIdCause':
				type = Type_User
				originator = cause.userName
				data = cause.userId
				break

			case 'com.cloudbees.jenkins.GitHubPushCause':
				type = Type_SCM
				originator = cause.pushedBy
				data = "GitHub"
				break

			case 'com.sonyericsson.rebuild.RebuildCause':
				type = Type_Rebuild
				originator = (cause as Cause.UpstreamCause).upstreamProject
				data = (cause as Cause.UpstreamCause).upstreamBuild
				break

			default:
				type = Type_Unknown
				originator = "N/A"
				data = "N/A"
		}
	}

	String print() {
		return "Cause(${className}): ${description}"
	}
}
