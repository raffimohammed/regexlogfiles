#!/bin/env bash
set +x
PATTERN1="oentuheontuheo"
PATTERN2="ountheonut\"oeuntohenuth\"ounteohun"  # Escape any double quotes that are a part of the pattern to be searched for
PATTERN3="sntp\.ysn\.yptfsn" # Escape the period if that's what you are looking for
PATTERN4="Not enough storage is available" 
PATTERN5="ohtundoehtundothudeontoueont"
PATTERN6="ounthoetnoetnvwmontehuonthu"
PATTERN7="java.lang.OutOfMemoryError"

EMAIL=email@meail.com

function check_to_ensure_patternlog_file_gets_updated 
{
	DUPED_LOG_FILE=$1
	ORIGINAL_LOG_FILE=$2	
	test ! -e ${ORIGINAL_LOG_FILE} &&  return  # The log file that's supposed to be searched for the patterns does not exist so just return
	test ! -e ${DUPED_LOG_FILE} && touch -t 7801000000 ${DUPED_LOG_FILE}
	MODIFIED_TIME_DUPED_LOG_FILE=$( stat --format=%Y ${DUPED_LOG_FILE} )
	MODIFIED_TIME_ORIGINAL_LOG_FILE=$( stat --format=%Y ${ORIGINAL_LOG_FILE} )
	MODIFIED_TIME_DIFF_SECONDS=$( expr ${MODIFIED_TIME_ORIGINAL_LOG_FILE} - ${MODIFIED_TIME_DUPED_LOG_FILE} )
	MODIFIED_TIME_DIFF_MINUTES=$( echo "${MODIFIED_TIME_DIFF_SECONDS} / 60 " | bc )
	if [ ${MODIFIED_TIME_DIFF_MINUTES} -gt 2 -a -s ${ORIGINAL_LOG_FILE} ]
	then 
		ps -ef | grep user1 | grep "[t]ail -f ${ORIGINAL_LOG_FILE}" # does the tail process that should be tailing off the original log file to the duped log file exit ?
		if [ $? -eq 0 ]
		then
			#It does exist, kill them
			ps -ef | grep user1 | grep "[t]ail -f ${ORIGINAL_LOG_FILE}" | awk '{print $2}' | xargs kill -9 
		fi
		nohup tail -f ${ORIGINAL_LOG_FILE} >> ${DUPED_LOG_FILE} &
	fi
}
function nullify_log_file 
{
	FILE=$1
	MAXFILESIZE=$2
	FILESIZE=$( ls -s ${FILE} | awk '{print $1}' ) # list the file size in  blocks
	(( ${FILESIZE} > ${MAXFILESIZE} )) &&  cat /dev/null > ${FILE}
}	
while true
do
	check_to_ensure_patternlog_file_gets_updated /tmp/.duped_log_file /path/original_log_file
	egrep "(${PATTERN1}|${PATTERN2}|${PATTERN3}|${PATTERN4}|${PATTERN5}|${PATTERN7})" /tmp/.duped_log_file >> /tmp/.duped_log_file.pattern.log
	if [ -s /tmp/.duped_log_file.pattern.log ]
	then
		cat /tmp/.duped_log_file.pattern.log | mail -s"pattern found" -r patternfound@email.com ${EMAIL}
		cat /dev/null > /tmp/.duped_log_file  			# Now that you have found a certain pattern at a certain point of time you don't want to reconsider again.
		cat /dev/null > /tmp/.duped_log_file.pattern.log  	# This would have the log message with the pattern you are looking for. You want to dev null this to prevent it from getting reconsidered again.
									# Don't dev null the original log file as that is the file your fellow developers/operations team members would be using.
	else
		nullify_log_file /tmp/.duped_log_file 100000 # If this log file goes  over 100000 blocks empty it
	fi
done
