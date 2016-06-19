#!/usr/bin/python
#
# This script is designed to run inside of mod_python: https://wiki.python.org/moin/ModPython
#
#

import md5
import sha
import cgi
import mod_python

from datetime import datetime

# directory for storing the reports
reports_dir = "/var/log/crashes/"

# success and error pages
success_page = "support.html"
error_page = "error.html"

# email for reports and subject line
report_email = "support@example.com"
report_subject = "Trouble Report: "

# index action for mod_python
def index():
    report_date = datetime.now()
    report_digest = str(report_date)
    report_hash = sha.new(report_digest).hexdigest()

    # read the form data via the cgi module
    report_form = cgi.FormContentDict()
