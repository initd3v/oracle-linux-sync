#!/bin/bash

#	Author		: Manegold, Martin
#	Description	: This bash script syncs the *.rpm packages of a Oracle Linux repositories based on the index URI. Optionally it provides the possibility to create the yum sub information based on the createrepo-c program.
#	Ressources	: createrepo-c -> https://github.com/rpm-software-management/createrepo_c

# MAIN CONFIGURATION ############################################################################

## VERBOSITY_LEVEL
### "1"		= log to file at REPO_DOWNLOAD_PATH and systemd journal if available
### "0"			= disable all logging
### "2"				= all other enable full logging - log to console, file at REPO_DOWNLOAD_PATH and systemd journal if available
#### e.g. VERBOSITY_LEVEL="system"
VERBOSITY_LEVEL="all"

## REPO_DOWNLOAD_INDEX_URIS
### *				= paste URLs of index page of Oracle repository to
#### e.g. VERBOSITY_LEVEL="system"
REPO_DOWNLOAD_INDEX_URIS="https://yum.oracle.com/repo/OracleLinux/OL8/UEKR6/RDMA/x86_64/index.html https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64/index.html"
REPO_DOWNLOAD_PATH="/tmp"
REPO_RPM_METADATA_CREATION=false

# OPTIONAL CONFIGURATION ########################################################################
## set CMD_CREATEREPO if REPO_RPM_METADATA_CREATION is set to true in MAIN CONFIGURATION

CMD_CREATEREPO="/usr/bin/createrepo_c"

#################################################################################################

processOutput(){
	case $1 in
		"error")
			if [ ${VERBOSITY_LEVEL} -ne 0 ] ; then
				TMP_TIME=`${CMD_DATE} +"%d%m%Y_%H%M%S"`
				if [ -d "${REPO_DOWNLOAD_PATH}" ] ; then
					${CMD_ECHO} -e "${TMP_TIME}$2" >> "${REPO_DOWNLOAD_PATH}/oraclesync.log"
				fi
				if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
					${CMD_ECHO} -e "$2" | ${CMD_SYSTEMDCAT} -t OracleLinuxRepoSync >/dev/null 2>&1
				fi
				if  [ ${VERBOSITY_LEVEL} -ne 1 ] ; then
					${CMD_ECHO} -e "$2"
				fi
				exit ${TMP_FALSE}
			fi
			;;
		"message")
			if [ ${VERBOSITY_LEVEL} -ne 0 ]; then
				TMP_TIME=`/bin/date +"%d%m%Y_%H%M%S"`
				if [ -d "${REPO_DOWNLOAD_PATH}" ] ; then
					${CMD_ECHO} -e "${TMP_TIME}$2" >> "${REPO_DOWNLOAD_PATH}/oraclesync.log"
				fi
				if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
					${CMD_ECHO} "$2" | ${CMD_SYSTEMDCAT} -t OracleLinuxRepoSync >/dev/null 2>&1
				fi
				if [ ${VERBOSITY_LEVEL} -ne 1 ] ; then
					${CMD_ECHO} -e "$2"
				fi
			fi
			;;
		*)
			if [ ${VERBOSITY_LEVEL} -ne 0 ] ; then
				TMP_TIME=`/bin/date +"%d%m%Y_%H%M%S"`
				${CMD_ECHO} -e "${TMP_TIMfor E}ERROR: No valid event can be prosecessed. Possibly script error exists for subroutine call precessOutput().\n" >> "${LOG_PATH}/cgroupmount.log"
			fi
			;;
	esac
}

processInitialization(){
	# set script execution path
	SCRIPT_NAME=`/usr/bin/realpath "$0"`
	SCRIPT_PATH=`/usr/bin/dirname "$SCRIPT_NAME"`

	# set exit codes
	/usr/bin/true
	TMP_TRUE=$?
	/usr/bin/false
	TMP_FALSE=$?

	# check on write permission for current user
	if [ ! -w "${REPO_DOWNLOAD_PATH}" ] ; then
        /bin/echo -e "ERROR: The defined download folder '${REPO_DOWNLOAD_PATH}' is not writable for the current USER (${USER})."
        exit ${TMP_FALSE}
	fi

	# initialize log
	if [ "${TMP_VALUE}x" == "x" ] ; then
		/bin/echo -e  "WARNING: The verbosity level variable is not set. Assuming verbosity level 2."
		VERBOSITY_LEVEL=2
	fi

	if [ ${VERBOSITY_LEVEL} -ne 0 ] && [ ! -f "${REPO_DOWNLOAD_PATH}/oraclesync.log" ] ; then
		/bin/echo "" > "${REPO_DOWNLOAD_PATH}/oraclesync.log"
	fi

	# set command binary paths
	CMD_ECHO="/bin/echo"
	CMD_AWK="/usr/bin/awk"
	CMD_WHEREIS="/usr/bin/whereis"
	CMD_DATE=`${CMD_WHEREIS} date | ${CMD_AWK} '{ print $2 }'`
	CMD_GREP=`${CMD_WHEREIS} grep | ${CMD_AWK} '{ print $2 }'`
	CMD_CURL=`${CMD_WHEREIS} curl | ${CMD_AWK} '{ print $2 }'`
	CMD_SED=`${CMD_WHEREIS} sed | ${CMD_AWK} '{ print $2 }'`
	CMD_MKDIR=`${CMD_WHEREIS} mkdir | ${CMD_AWK} '{ print $2 }'`
	CMD_SHA256SUM=`${CMD_WHEREIS} sha256sum | ${CMD_AWK} '{ print $2 }'`
	CMD_CAT=`${CMD_WHEREIS} cat | ${CMD_AWK} '{ print $2 }'`
	CMD_SLEEP=`${CMD_WHEREIS} sleep | ${CMD_AWK} '{ print $2 }'`

	for TMP in "${CMD_ECHO}" "${CMD_AWK}" "${CMD_WHEREIS}" "${CMD_DATE}" "${CMD_GREP}" "${CMD_CURL}" "${CMD_SED}" "${CMD_MKDIR}" "${CMD_SHA256SUM}" "${CMD_CAT}" "${CMD_SLEEP}" ; do
		if [ "${TMP}x" == "x" ] || [ ! -f "${TMP}" ] ; then
			TMP_NAME=(${!TMP@})
			ERROR="${ERROR}ERROR: The bash variable '${TMP_NAME}' with value '${TMP}' does not reference to a valid command binary path or is empty.\n"
		fi
	done

	if [ "${ERROR}x" != "x" ] ; then
		processOutput "error" "${ERROR}"
	fi

	processOutput "message" "INFO: The command binary paths were successfully set."

	# set optional command binary paths
	CMD_SYSTEMDCAT=`${CMD_WHEREIS} systemd-cat | ${CMD_AWK} '{ print $2 }'`

	# processParameters
	processParameters

	# check configuration
    for TMP in "${REPO_DOWNLOAD_INDEX_URIS}" "${REPO_DOWNLOAD_PATH}" "${REPO_RPM_METADATA_CREATION}" ; do
        if [ "${TMP}x" == "x" ] ; then
            TMP_NAME=(${!TMP@})
            ERROR="${ERROR}ERROR: The variable '${TMP_NAME}' with value '${TMP}' is empty. Please define a valid value.\n"
        fi
    done

	if [ ! -d "${REPO_DOWNLOAD_PATH}" ] ; then
		ERROR="${ERROR}ERROR: The download directory '${REPO_DOWNLOAD_PATH}' does not exist. It is needed as primary sync path.\n"
	fi

	if [ "${REPO_RPM_METADATA_CREATION}" == true ] ; then
		CMD_CREATEREPO="${CMD_CREATEREPO:-$(${CMD_WHEREIS} createrepo_c | ${CMD_AWK} '{ print $2 }')}"
		if [ "${CMD_CREATEREPO}x" == "x" ] || [ ! -f "${CMD_CREATEREPO}" ] ; then
			TMP_NAME=(${!CMD_CREATEREPO@})
                        ERROR="${ERROR}ERROR: The bash variable '${TMP_NAME}' with value '${CMD_CREATEREPO}' does not reference to a valid command binary path or is empty. It must be correctly set when variable 'REPO_RPM_METADATA_CREATION' is set 'true'.\n"
		fi
	else
		REPO_RPM_METADATA_CREATION=false
	fi

	for TMP in ${REPO_DOWNLOAD_INDEX_URIS} ; do
		TMP_RETURN=`${CMD_CURL} -s -o /dev/null -w "%{response_code}" "${TMP}"`
		if [ "${TMP_RETURN}" != "200" ] ; then
			ERROR="${ERROR}ERROR: The URI '${TMP}' can not be reached. Please check that it is set correctly.\n"
		fi
	done

	if [ "${ERROR}x" != "x" ] ; then
		processOutput "error" "${ERROR}"
	fi

	processOutput "message" "INFO: The configuration was checked successfully."
}

processParameters() {
	TMP_COUNTER=1
	while [ ${TMP_COUNTER} -lt ${COUNT_PARAMETERS} ] ; do
		TMP_INDEX=`${CMD_ECHO} "${PARAMETERS}" | ${CMD_AWK}  -F " --|^--| -|^-" '{ print $(1+'"${TMP_COUNTER}"') }' | ${CMD_SED} -e 's/=/%3D/g' -e 's/%3D/=/1' | ${CMD_AWK}  -F "=" '{ print $1 }'`
		TMP_VALUE=`${CMD_ECHO} "${PARAMETERS}" | ${CMD_AWK}  -F " --|^--| -|^-" '{ print $(1+'"${TMP_COUNTER}"') }' | ${CMD_SED} -e 's/=/%3D/g' -e 's/%3D/=/1' | ${CMD_AWK}  -F "=" '{ print $2 }'`
	echo $TMP_VALUE
		case "${TMP_INDEX}" in
		"--verbosity" | "-v" | "v")
			if [ ${TMP_VALUE} -eq 0 ] || [ ${TMP_VALUE} -lt 3 ] ; then
				VERBOSITY_LEVEL="${TMP_VALUE}"
			else
				ERROR="${ERROR}ERROR: The verbosity level must be a number betwenn 0 and 2 but is '${TMP_VALUE}'."
			fi
			;;
		"--configuration" | "-c" | "c")
			if [ "${TMP_VALUE}x" != "x" ] && [ -f "${TMP_VALUE}" ] ; then
				if [ -O "${TMP_VALUE}" ] ; then
					source "${TMP_VALUE}"
				else
					ERROR="${ERROR}ERROR: The defined configuration '${TMP_VALUE}' file is not owned by the executing user '${USER}'."
				fi
			else
				ERROR="${ERROR}ERROR: The defined configuration '${TMP_VALUE}' does not exist."
			fi
			break
			;;
		"--directory" | "-d" | "d")
			REPO_DOWNLOAD_PATH="${TMP_VALUE}"
			;;
		"--metadata" | "-m" | "m")
			REPO_RPM_METADATA_CREATION="${TMP_VALUE}"
			;;
		"--url" | "-u" | "u")
			REPO_DOWNLOAD_INDEX_URIS="${REPO_DOWNLOAD_INDEX_URIS} ${TMP_VALUE}"
			;;
		*)
			ERROR="${ERROR}ERROR: The parameter '${TMP_INDEX}' with value '${TMP_VALUE}' is not a valid pair of parameter and value."
			;;
		esac
		if [ "${ERROR}x" != "x" ] ; then
			processOutput "error" "${ERROR}"
		fi
		TMP_COUNTER=$(( TMP_COUNTER + 1 ))
	done
}

processSync() {
	# download *.rpm packages from sources
	for TMP_URI in ${REPO_DOWNLOAD_INDEX_URIS} ; do
		TMP_RETURN=`${CMD_CURL} -s "${TMP_URI}" | ${CMD_GREP} "\.rpm" | ${CMD_AWK} -F '<a href="' '{print $2}' | ${CMD_AWK} -F '">' '{print $1}'`
		if [ "${TMP_RETURN}x" == "x" ] ; then
			processOutput "message" "WARNING: The URI ${TMP_URI} does not return any *.rpm package. Please check if it is a valid Oracle Linux index page."
		else
			REPO_DOWNLOAD_BASE_URI=`${CMD_ECHO} "${TMP_URI}" | ${CMD_SED} 's/index\.html//g'`
			if [ "${REPO_DOWNLOAD_BASE_URI}x" == "x" ] ; then
				TMP_NAME=(${!REPO_DOWNLOAD_BASE_URI@})
				ERROR="${ERROR}ERROR: The bash variable '${TMP_NAME}' with value '${REPO_DOWNLOAD_BASE_URI}' is empty. Whether the base URI, architecture, Oracle Linux version or repository name could not be extracted from the given URI.\n"
			fi

            TMP_COUNTER=1
			REPO_DOWNLOAD_FOLDER_NAMES=""
            while [ "${TMP_FOLDER_NAME}x" != "x" ] || [ $TMP_COUNTER -eq 1 ] ; do
                TMP_FOLDER_NAME=`${CMD_ECHO} "${REPO_DOWNLOAD_BASE_URI}" | ${CMD_AWK} -F '/' '{print $(5 +'"${TMP_COUNTER}"')}'`
                REPO_DOWNLOAD_FOLDER_NAMES="${REPO_DOWNLOAD_FOLDER_NAMES}/${TMP_FOLDER_NAME}"
                TMP_COUNTER=$(( $TMP_COUNTER + 1 ))
            done

			if [ ! -d "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}" ] ; then
				${CMD_MKDIR} -p "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}" > /dev/null 2>&1
				if [ $? -ne 0 ] ;  then
					processOutput "message" "WARNING: The download directory '${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}' could not be created. It will be skipped."
					continue
				fi
			fi

			for TMP_RETURN_RPM in ${TMP_RETURN} ; do
				TMP_FILE_NAME=`${CMD_ECHO} "${TMP_RETURN_RPM}" | ${CMD_AWK} -F '/' '{print $2}'`
				#TMP_FILE_SHA256SUM=`${CMD_CURL} -s -o /dev/null "${REPO_DOWNLOAD_BASE_URI}${TMP_RETURN_RPM}" | ${CMD_SHA256SUM}`
				TMP_FILE_SHA256SUM=`${CMD_CURL} -s -I "${REPO_DOWNLOAD_BASE_URI}${TMP_RETURN_RPM}" | ${CMD_GREP} "Last-Modified" | ${CMD_SHA256SUM}`
				if [ -f "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}${TMP_FILE_NAME}.uri.sha256" ] ; then
					TMP_FILE_SHA256SUM_COMPARE=`${CMD_CAT} "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}${TMP_FILE_NAME}.uri.sha256"`
                fi
                if [ "${TMP_FILE_SHA256SUM}" == "${TMP_FILE_SHA256SUM_COMPARE}" ] ; then
                    processOutput "message" "WARNING: The file ${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}${TMP_FILE_NAME}.uri.sha256 has the same checksum as the URI source file. File download for ${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}${TMP_FILE_NAME} will be skipped."
                    continue
				else
					${CMD_ECHO} "${TMP_FILE_SHA256SUM}" > "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}${TMP_FILE_NAME}.uri.sha256"
				fi

				cd "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}"
				${CMD_CURL} -s -O "${REPO_DOWNLOAD_BASE_URI}${TMP_RETURN_RPM}"
				if [ $? -eq 0 ] ;  then
					processOutput "message" "INFO: The URI file '${REPO_DOWNLOAD_BASE_URI}${TMP_RETURN_RPM}' was downloaded to '${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}'."
					${CMD_SLEEP} 0.01
				else
					processOutput "message" "WARNING: The URI file '${REPO_DOWNLOAD_BASE_URI}${TMP_RETURN_RPM}' could not be downloaded."
				fi
			done

			if [ "${REPO_RPM_METADATA_CREATION}" == true ] ; then
                ${CMD_CREATEREPO} --update "${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}" >/dev/null 2>&1
                if [ $? -eq 0 ] ;  then
					processOutput "message" "INFO: The repository metadata for folder '${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}' was successfully generated."
				else
					processOutput "message" "WARNING: The repository metadata for folder '${REPO_DOWNLOAD_PATH}${REPO_DOWNLOAD_FOLDER_NAMES}' could not be generated."
				fi
            fi
		fi
	done
}

PARAMETERS="$*"
COUNT_PARAMETERS=$(( $# + 1 ))

processInitialization "$?"
#processSync

