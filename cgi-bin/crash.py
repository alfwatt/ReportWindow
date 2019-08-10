#!/usr/bin/python

import md5
import sha
import cgi

from datetime import datetime
from mod_python import util

# directory for storing the reports
reports_label = "crash_"
reports_dir = "/var/log/crashes/"

# success and error pages
success_page = "support.html"
error_page = "error.html"

# email for reports and subject line
report_email = "support@example.com"
report_subject = "Trouble Report: "

# report information
report_date = datetime.now()
report_digest = reports_label + str(report_date)
report_path = reports_dir + report_digeset
report_hash = sha.new(report_digest).hexdigest()

# 

