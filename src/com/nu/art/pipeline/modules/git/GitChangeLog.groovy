package com.nu.art.pipeline.modules.git

import java.text.SimpleDateFormat

class GitChangeLog {
	final String hash
	final Date date
	final String author
	final String comment

	GitChangeLog(commit) {
		def result = (commit =~ /^([0-9a-f]{7}) ([0-9: \+-]{25}) (.*?) (.*)$/)
		hash = result[0][1]
		date = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss zzz").parse(result[0][2])
		author = result[0][3]
		comment = result[0][4]
	}
}
