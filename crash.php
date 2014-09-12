<?php

// directory on the web server for storing the reports
$reports_dir = "/var/db/crashes/";

// success and error pages, once the report is posted
$success = "support.html";
$error = "error.html";

// serial number (NB: only unique if you get less than one report a second)
$serial = date("Ymd-HisO");

// email and subject of the report
$email = "support@mydomain.com";
$subject = "Crash Report: " . $serial;

// email and report message content
$message = "crash report: " . $serial;
$message .= "\n\n" . urldecode($_POST["comments"]);
$message .= "\n\nfiles: " . urldecode(var_export($_FILES, true));

// first log the message before any further processsing
if( isset( $reports_dir))
{
	$logfile = "$reports_dir/$serial.log";
	$file = fopen($logfile,"w");
	if( isset( $file))
	{
		fwrite($file, $message);
		fwrite($file, "\n\nbody: \n" . file_get_contents('php://input'));
		fclose($file);
	}
}

// check for errors

if( !isset($_FILES["report"]))
{
	error_log("crash report upload error: $serial " . $_FILES["report"]["error"]);
	header("Location: $error?crash report file is empty!");
	return;
}

if ($_FILES["report"]["size"] > 1000000) // about a meg is a reasonable limit
{
	error_log("crash report upload oversize: $serial " . $_FILES["report"]["size"]);
	header("Location: $error?crash report upload error!");
	return;
}

if ( $_FILES["report"]["error"] > 0)  // bail out if there was an upload error
{
	error_log("crash report upload error: $serial " . $_FILES["report"]["error"]);
	header("Location: $error?crash report upload error!");
	return;
}

$report_name = $serial . "-" . $_FILES["report"]["name"];
$report_file = $reports_dir . $report_name;

if (file_exists($report_file))  // TODO use the serial number for the report file name, also log the notes
{
	error_log("crash report duplicate upload: $serial " . $_FILES["report"]["error"]);
	header("Location: $error?crash report duplicate upload: $report_name");
	return;
}
else
{
	move_uploaded_file($_FILES["report"]["tmp_name"], $report_file);
}

// log the report metadata to the web server error log
error_log("crash report: " . $serial 
		. " type: " . $_FILES["report"]["type"] 
		. " size: " . $_FILES["report"]["size"]
		. " temp: " . $_FILES["report"]["tmp_name"]
		. " name: " . $report_file);

// finally, send an email if configured to do so
if( isset( $email))
{
	// Create a random boundary
	$boundary = base64_encode(MD5((string)rand()));
	
	$headers  = "From: $email\n";
	$headers .= "X-Mailer: PHP/".phpversion()."\n";
	$headers .= "MIME-Version: 1.0\n";
	$headers .= "Content-Type: multipart/mixed; boundary=\"$boundary\"\n";
	$headers .= "Content-Transfer-Encoding: 8bit\n\n";
	$headers .= "This is a MIME encoded message.\n\n";
	
	$headers .= "--$boundary\n";
	$headers .= "Content-Type: text/plain; charset=\"utf-8\"\n";
	$headers .= "Content-Transfer-Encoding: 8bit\n\n";
	$headers .= "$message\n\n\n";
	
	$headers .= "--$boundary\n";
	$headers .= "Content-Type: application/octet-stream; name=\"$report_name\"\n";
	$headers .= "Content-Transfer-Encoding: base64\n";
	$headers .= "Content-Disposition: attachment\n\n";
	
	// we limited this to 1mb, so it should be OK to load into memory, probably
	$handle = fopen($report_file, "r");
	$report = fread($handle, filesize($report_file));
	fclose($handle);
	
	$headers .= chunk_split(base64_encode($report))."\n";
	$headers .= "--$boundary--";
	
	if( !mail($email, $subject, "", utf8_encode($headers)))
	{
		header("Location: $error?could not send mail to: $email for case number: $serial");
		return;
	}
}

header("Location: $success?serial=$serial");
return;

?>
