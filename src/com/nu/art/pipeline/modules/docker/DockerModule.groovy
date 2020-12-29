package com.nu.art.pipeline.modules.docker

import com.nu.art.pipeline.workflow.WorkflowModule

class DockerModule
	extends WorkflowModule {

	DockerConfig create(String key, String version) {
		return new DockerConfig(this, key, version)
	}
}


//+ docker exec -w /data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV 783e39a7-003b-488d-b616-24720851b5a4 bash -c bash build-and-install.sh --install --no-build --link
//+ docker exec -w /data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV@3 c45656ff-ff76-4683-9667-5bc76561f6ea bash -c bash build-and-install.sh --install --no-build --link
//
//docker run --rm -d --net=host --name c45656ff-ff76-4683-9667-5bc76561f6ea
//	-e USER=jenkins
//	-v ****:**** -v ****:****
//	-v /home/jenkins/.config:/home/jenkins/.config
//	-v /home/jenkins/.ssh/id_rsa:/home/jenkins/.ssh/id_rsa
//	-v /home/jenkins/.ssh/known_hosts:/home/jenkins/.ssh/known_hosts
//	eu.gcr.io/ir-infrastructure-246111/jenkins-ci-python-env:1.0.18 tail -f /dev/null
//
//docker run --rm -d --net=host --name 783e39a7-003b-488d-b616-24720851b5a4
//	-v ****:**** -v ****:****
//	-e WORKSPACE=/data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV
//	-e BUILD_NUMBER=46
//	-v /data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV:/data/jenkins/workspace/v2_upload_elliq_firebase_data-DEV
//	eu.gcr.io/ir-infrastructure-246111/jenkins-ci-python-env:1.0.18 tail -f /dev/null
