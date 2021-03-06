#======  FUNCTION  ============================================================
#          NAME:  rotateLogsByTime
#   DESCRIPTION:  Rotates log files based on size or time.
#    PARAMETERS:  The log file name to take action against
#       RETURNS:  0 regardless of result.
#==============================================================================
function rotateLogsByTime
{
    set +o noclobber;
    typeset SCRIPT_NAME="logging.sh";
    typeset FUNCTION_NAME="${FUNCNAME[0]}";
    typeset -i COUNTER=0;
    typeset -i RETURN_CODE=0;

    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && writeLogEntry "PERFORMANCE" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} START: $(/usr/bin/env date +"${TIMESTAMP_OPTS}")";
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && typeset -i START_EPOCH=$(/usr/bin/env date +"%s");

    [ ! -z "${ENABLE_VERBOSE}" -a "${ENABLE_VERBOSE}" = "${_TRUE}" ] && set -x || set +x;
    [ ! -z "${ENABLE_TRACE}" -a "${ENABLE_TRACE}" = "${_TRUE}" ] && set -v || set +v;

    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} -> enter";
    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Provided arguments: ${*}";

    typeset -i DATESTAMP=$(/usr/bin/env date +"%s");
    typeset -i ROLLOVER_CHECK=$(echo "${ROLLOVER_PERIOD} * 60 * 60" | /usr/bin/env bc);

    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "DATESTAMP -> ${DATESTAMP}";
    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ROLLOVER_CHECK -> ${ROLLOVER_CHECK}";

    for LOG_FILE in $(/usr/bin/env ls -ltr ${LOG_ROOT} | /usr/bin/env egrep "^-" | /usr/bin/env tail -n +2 | /usr/bin/env awk '{print $NF}')
    do
        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "LOG_FILE -> ${LOG_FILE}";
        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env stat -L --format %Y \"${LOG_ROOT}/${LOG_FILE}\"";

        typeset -i FILE_STAT_TIME=$(/usr/bin/env stat -L --format %Y "${LOG_ROOT}/${LOG_FILE}");

        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "FILE_STAT_TIME -> ${FILE_STAT_TIME}";

        if [ ${FILE_STAT_TIME} -gt ${ROLLOVER_CHECK} ]
        then
            case "${ARCHIVE_ENABLED}" in
                "${_TRUE}")
                    while [ ${COUNTER} -le $(echo ${LOG_RETENTION_PERIOD} + 1 | /usr/bin/env bc) ]
                    do
                        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "A -> ${COUNTER}";

                        if [ -f "${LOG_ROOT}/${LOG_FILE}.${COUNTER}" ]
                        then
                            typeset ELIGIBLE_FILE="${LOG_FILE}.${COUNTER}";
                            typeset -i CURRENT_NUMBER=$(cut -d "." -f 3 <<< "${ELIGIBLE_FILE}");
                            typeset -i ADD_NUMBER=$(echo ${CURRENT_NUMBER} + 1 | /usr/bin/env bc);

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ELIGIBLE_FILE -> ${ELIGIBLE_FILE}";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_NUMBER -> ${CURRENT_NUMBER}";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ADD_NUMBER -> ${ADD_NUMBER}";

                            if [ -f "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}" ]
                            then
                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cp \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}\" \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\"";

                                /usr/bin/env cp "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}" "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}";

                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}\" | awk '{print $1}'";
                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\" | awk '{print $1}'";

                                typeset -i CURRENT_FILE_CKSUM=$(/usr/bin/env cksum "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}" | awk '{print $1}');
                                typeset -i ARCHIVE_FILE_CKSUM=$(/usr/bin/env cksum "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}" | awk '{print $1}');

                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_FILE_CKSUM -> ${CURRENT_FILE_CKSUM}";
                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVE_FILE_CKSUM -> ${ARCHIVE_FILE_CKSUM}";

                                if [ ${ARCHIVE_FILE_CKSUM} -ne ${CURRENT_FILE_CKSUM} ]
                                then
                                    writeLogEntry "ERROR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                                    writeLogEntry "STDERR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                                fi

                                [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
                                [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
                            fi

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cp \"${LOG_ROOT}/${LOG_FILE}.${COUNTER}\" \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\"";

                            /usr/bin/env cp "${LOG_ROOT}/${LOG_FILE}.${COUNTER}" "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}";

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${LOG_ROOT}/${LOG_FILE}.${COUNTER}\" | awk '{print $1}'";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\" | awk '{print $1}'";

                            typeset -i CURRENT_FILE_CKSUM=$(/usr/bin/env cksum "${LOG_ROOT}/${LOG_FILE}.${COUNTER}" | awk '{print $1}');
                            typeset -i ARCHIVE_FILE_CKSUM=$(/usr/bin/env cksum "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}" | awk '{print $1}');

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_FILE_CKSUM -> ${CURRENT_FILE_CKSUM}";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVE_FILE_CKSUM -> ${ARCHIVE_FILE_CKSUM}";

                            if [ ${ARCHIVE_FILE_CKSUM} -ne ${CURRENT_FILE_CKSUM} ]
                            then
                                writeLogEntry "ERROR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                                writeLogEntry "STDERR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                            else
                                /usr/bin/env rm -f "${LOG_ROOT}/${LOG_FILE}.${COUNTER}";
                            fi
                        fi

                        (( COUNTER += 1 ));

                        [ ! -z "${ELIGIBLE_FILE}" ] && unset -v ELIGIBLE_FILE;
                        [ ! -z "${CURRENT_NUMBER}" ] && unset -v CURRENT_NUMBER;
                        [ ! -z "${ADD_NUMBER}" ] && unset -v ADD_NUMBER;
                        [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
                        [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
                    done

                    ## clean up anything higher than the retention count
                    for ARCHIVED_FILE in ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.*
                    do
                        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVED_FILE -> ${ARCHIVED_FILE}";

                        [ -z "${ARCHIVED_FILE}" ] || [ ! -f "${ARCHIVED_FILE}" ] && continue || typeset -i ARCHIVE_NUMBER=$(awk -F "." '{print $NF}' <<< "${ARCHIVED_FILE}");

                        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVED_FILE -> ${ARCHIVED_FILE}";

                        [ ${ARCHIVE_NUMBER} -ge ${LOG_RETENTION_PERIOD} ] && rm -f "${ARCHIVED_FILE}";

                        [ ! -z "${ARCHIVE_NUMBER}" ] && unset -v ARCHIVE_NUMBER;
                        [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
                    done
                    ;;
            esac

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cp \"${LOG_ROOT}/${LOG_FILE}\" \"${LOG_ROOT}/${LOG_FILE}.0\"";

            /usr/bin/env cp "${LOG_ROOT}/${LOG_FILE}" "${LOG_FILE}.0";

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${LOG_ROOT}/${LOG_FILE}.${COUNTER}\" | awk '{print $1}'";
            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\" | awk '{print $1}'";

            typeset -i CURRENT_FILE_CKSUM=$(/usr/bin/env cksum "${LOG_ROOT}/${LOG_FILE}" | awk '{print $1}');
            typeset -i ARCHIVE_FILE_CKSUM=$(/usr/bin/env cksum "${LOG_ROOT}/${LOG_FILE}.0" | awk '{print $1}');

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_FILE_CKSUM -> ${CURRENT_FILE_CKSUM}";
            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVE_FILE_CKSUM -> ${ARCHIVE_FILE_CKSUM}";

            if [ ${ARCHIVE_FILE_CKSUM} -ne ${CURRENT_FILE_CKSUM} ]
            then
                writeLogEntry "ERROR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE} and ${LOG_ROOT}/${LOG_FILE}.0 do NOT match";
                writeLogEntry "STDERR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE} and ${LOG_ROOT}/${LOG_FILE}.0 do NOT match";
            fi

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cat /dev/null >| \"${LOG_FILE}\"";

            /usr/bin/env cat /dev/null >| ${LOG_ROOT}/${LOG_FILE};
        fi

        [ ! -z "${ELIGIBLE_FILE}" ] && unset -v ELIGIBLE_FILE;
        [ ! -z "${CURRENT_NUMBER}" ] && unset -v CURRENT_NUMBER;
        [ ! -z "${ADD_NUMBER}" ] && unset -v ADD_NUMBER;
        [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
        [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
        [ ! -z "${ARCHIVE_NUMBER}" ] && unset -v ARCHIVE_NUMBER;
        [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
        [ ! -z "${FILE_STAT_TIME}" ] && unset -v FILE_STAT_TIME;
        [ ! -z "${LOG_FILE}" ] && unset -v LOG_FILE;
    done

    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "RETURN_CODE -> ${RETURN_CODE}";
    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} -> exit";

    [ ! -z "${COUNTER}" ] && unset -v COUNTER;
    [ ! -z "${LOG_FILE}" ] && unset -v LOG_FILE;
    [ ! -z "${DATESTAMP}" ] && unset -v DATESTAMP;
    [ ! -z "${ROLLOVER_CHECK}" ] && unset -v ROLLOVER_CHECK;
    [ ! -z "${FILE_STAT_TIME}" ] && unset -v FILE_STAT_TIME;
    [ ! -z "${ELIGIBLE_FILE}" ] && unset -v ELIGIBLE_FILE;
    [ ! -z "${CURRENT_NUMBER}" ] && unset -v CURRENT_NUMBER;
    [ ! -z "${ADD_NUMBER}" ] && unset -v ADD_NUMBER;
    [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
    [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
    [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
    [ ! -z "${FILE_STAT_TIME}" ] && unset -v FILE_STAT_TIME;
    [ ! -z "${LOG_FILE}" ] && unset -v LOG_FILE;

    [ ! -z "${ENABLE_VERBOSE}" -a "${ENABLE_VERBOSE}" = "${_TRUE}" ] && set -x || set +x;
    [ ! -z "${ENABLE_TRACE}" -a "${ENABLE_TRACE}" = "${_TRUE}" ] && set -x || set +x;

    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && typeset -i END_EPOCH=$(/usr/bin/env date +"%s");
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && typeset -i RUNTIME=$(( START_EPOCH - END_EPOCH ));
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && writeLogEntry "PERFORMANCE" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} TOTAL RUNTIME: $(( RUNTIME / 60)) MINUTES, TOTAL ELAPSED: $(( RUNTIME % 60)) SECONDS";
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && writeLogEntry "PERFORMANCE" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} END: $(/usr/bin/env date +"${TIMESTAMP_OPTS}")";

    [ ! -z "${FUNCTION_NAME}" ] && unset -v FUNCTION_NAME;
    [ ! -z "${SCRIPT_NAME}" ] && unset -v SCRIPT_NAME;

    return ${RETURN_CODE};
}

#======  FUNCTION  ============================================================
#          NAME:  rotateLogsBySize
#   DESCRIPTION:  Rotates log files based on size or time.
#    PARAMETERS:  The log file name to take action against
#       RETURNS:  0 regardless of result.
#==============================================================================
function rotateLogsBySize
{
    set +o noclobber;
    typeset SCRIPT_NAME="logging.sh";
    typeset FUNCTION_NAME="${FUNCNAME[0]}";
    typeset -i COUNTER=0;
    typeset -i RETURN_CODE=0;

    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && writeLogEntry "PERFORMANCE" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} START: $(/usr/bin/env date +"${TIMESTAMP_OPTS}")";
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && typeset -i START_EPOCH=$(/usr/bin/env date +"%s");

    [ ! -z "${ENABLE_VERBOSE}" -a "${ENABLE_VERBOSE}" = "${_TRUE}" ] && set -x || set +x;
    [ ! -z "${ENABLE_TRACE}" -a "${ENABLE_TRACE}" = "${_TRUE}" ] && set -v || set +v;

    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} -> enter";
    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Provided arguments: ${*}";

    typeset -i MAX_FILE_SIZE=$(echo "${FILE_SIZE_LIMIT} / 1024" | /usr/bin/env bc);

    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "MAX_FILE_SIZE -> ${MAX_FILE_SIZE}";

    for LOG_FILE in $(/usr/bin/env ls -ltr ${LOG_ROOT} | /usr/bin/env egrep "^-" | /usr/bin/env tail -n +2 | /usr/bin/env awk '{print $NF}')
    do
        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "LOG_FILE -> ${LOG_FILE}";
        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env stat -L --format %s \"${LOG_ROOT}/${LOG_FILE}\" ) / 1024 / 1024";

        typeset -i FILE_STAT_SIZE=$(echo $(( $( /usr/bin/env stat -L --format %s "${LOG_ROOT}/${LOG_FILE}" ) / 1024 / 1024 )));

        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "FILE_STAT_SIZE -> ${FILE_STAT_SIZE}";

        if [ ${FILE_STAT_SIZE} -gt ${MAX_FILE_SIZE} ]
        then
            case "${ARCHIVE_ENABLED}" in
                "${_TRUE}")
                    while [ ${COUNTER} -le $(echo ${LOG_RETENTION_PERIOD} + 1 | /usr/bin/env bc) ]
                    do
                        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "A -> ${COUNTER}";

                        if [ -f "${LOG_ROOT}/${LOG_FILE}.${COUNTER}" ]
                        then
                            typeset ELIGIBLE_FILE="${LOG_FILE}.${COUNTER}";
                            typeset -i CURRENT_NUMBER=$(cut -d "." -f 3 <<< "${ELIGIBLE_FILE}");
                            typeset -i ADD_NUMBER=$(echo ${CURRENT_NUMBER} + 1 | /usr/bin/env bc);

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ELIGIBLE_FILE -> ${ELIGIBLE_FILE}";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_NUMBER -> ${CURRENT_NUMBER}";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ADD_NUMBER -> ${ADD_NUMBER}";

                            if [ -f "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}" ]
                            then
                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cp \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}\" \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\"";

                                /usr/bin/env cp "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}" "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}";

                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}\" | awk '{print $1}'";
                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\" | awk '{print $1}'";

                                typeset -i CURRENT_FILE_CKSUM=$(/usr/bin/env cksum "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER}" | awk '{print $1}');
                                typeset -i ARCHIVE_FILE_CKSUM=$(/usr/bin/env cksum "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}" | awk '{print $1}');

                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_FILE_CKSUM -> ${CURRENT_FILE_CKSUM}";
                                [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVE_FILE_CKSUM -> ${ARCHIVE_FILE_CKSUM}";

                                if [ ${ARCHIVE_FILE_CKSUM} -ne ${CURRENT_FILE_CKSUM} ]
                                then
                                    writeLogEntry "ERROR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                                    writeLogEntry "STDERR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                                fi

                                [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
                                [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
                            fi

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cp \"${LOG_ROOT}/${LOG_FILE}.${COUNTER}\" \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\"";

                            /usr/bin/env cp "${LOG_ROOT}/${LOG_FILE}.${COUNTER}" "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}";

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${LOG_ROOT}/${LOG_FILE}.${COUNTER}\" | awk '{print $1}'";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\" | awk '{print $1}'";

                            typeset -i CURRENT_FILE_CKSUM=$(/usr/bin/env cksum "${LOG_ROOT}/${LOG_FILE}.${COUNTER}" | awk '{print $1}');
                            typeset -i ARCHIVE_FILE_CKSUM=$(/usr/bin/env cksum "${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}" | awk '{print $1}');

                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_FILE_CKSUM -> ${CURRENT_FILE_CKSUM}";
                            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVE_FILE_CKSUM -> ${ARCHIVE_FILE_CKSUM}";

                            if [ ${ARCHIVE_FILE_CKSUM} -ne ${CURRENT_FILE_CKSUM} ]
                            then
                                writeLogEntry "ERROR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                                writeLogEntry "STDERR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE}.${COUNTER} and ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER} do NOT match";
                            else
                                /usr/bin/env rm -f "${LOG_ROOT}/${LOG_FILE}.${COUNTER}";
                            fi
                        fi

                        (( COUNTER += 1 ));

                        [ ! -z "${ELIGIBLE_FILE}" ] && unset -v ELIGIBLE_FILE;
                        [ ! -z "${CURRENT_NUMBER}" ] && unset -v CURRENT_NUMBER;
                        [ ! -z "${ADD_NUMBER}" ] && unset -v ADD_NUMBER;
                        [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
                        [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
                    done

                    ## clean up anything higher than the retention count
                    for ARCHIVED_FILE in ${ARCHIVE_LOG_ROOT}/${LOG_FILE}.*
                    do
                        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVED_FILE -> ${ARCHIVED_FILE}";

                        [ -z "${ARCHIVED_FILE}" ] || [ ! -f "${ARCHIVED_FILE}" ] && continue || typeset -i ARCHIVE_NUMBER=$(awk -F "." '{print $NF}' <<< "${ARCHIVED_FILE}");

                        [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVED_FILE -> ${ARCHIVED_FILE}";

                        [ ${ARCHIVE_NUMBER} -ge ${LOG_RETENTION_PERIOD} ] && rm -f "${ARCHIVED_FILE}";

                        [ ! -z "${ARCHIVE_NUMBER}" ] && unset -v ARCHIVE_NUMBER;
                        [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
                    done
                    ;;
            esac

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cp \"${LOG_ROOT}/${LOG_FILE}\" \"${LOG_ROOT}/${LOG_FILE}.0\"";

            /usr/bin/env cp "${LOG_ROOT}/${LOG_FILE}" "${LOG_FILE}.0";

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${LOG_ROOT}/${LOG_FILE}.${COUNTER}\" | awk '{print $1}'";
            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cksum \"${ARCHIVE_LOG_ROOT}/${LOG_FILE}.${ADD_NUMBER}\" | awk '{print $1}'";

            typeset -i CURRENT_FILE_CKSUM=$(/usr/bin/env cksum "${LOG_ROOT}/${LOG_FILE}" | awk '{print $1}');
            typeset -i ARCHIVE_FILE_CKSUM=$(/usr/bin/env cksum "${LOG_ROOT}/${LOG_FILE}.0" | awk '{print $1}');

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "CURRENT_FILE_CKSUM -> ${CURRENT_FILE_CKSUM}";
            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "ARCHIVE_FILE_CKSUM -> ${ARCHIVE_FILE_CKSUM}";

            if [ ${ARCHIVE_FILE_CKSUM} -ne ${CURRENT_FILE_CKSUM} ]
            then
                writeLogEntry "ERROR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE} and ${LOG_ROOT}/${LOG_FILE}.0 do NOT match";
                writeLogEntry "STDERR" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "Checksums for file ${LOG_ROOT}/${LOG_FILE} and ${LOG_ROOT}/${LOG_FILE}.0 do NOT match";
            fi

            [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "EXEC: /usr/bin/env cat /dev/null >| \"${LOG_FILE}\"";

            /usr/bin/env cat /dev/null >| ${LOG_ROOT}/${LOG_FILE};
        fi

        [ ! -z "${ELIGIBLE_FILE}" ] && unset -v ELIGIBLE_FILE;
        [ ! -z "${CURRENT_NUMBER}" ] && unset -v CURRENT_NUMBER;
        [ ! -z "${ADD_NUMBER}" ] && unset -v ADD_NUMBER;
        [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
        [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
        [ ! -z "${ARCHIVE_NUMBER}" ] && unset -v ARCHIVE_NUMBER;
        [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
        [ ! -z "${FILE_STAT_SIZE}" ] && unset -v FILE_STAT_SIZE;
        [ ! -z "${FILE_STAT_SIZE}" ] && unset -v FILE_STAT_SIZE;
    done

    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "RETURN_CODE -> ${RETURN_CODE}";
    [ ! -z "${ENABLE_DEBUG}" -a "${ENABLE_DEBUG}" = "${_TRUE}" ] && writeLogEntry "DEBUG" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} -> exit";

    [ ! -z "${COUNTER}" ] && unset -v COUNTER;
    [ ! -z "${LOG_FILE}" ] && unset -v LOG_FILE;
    [ ! -z "${DATESTAMP}" ] && unset -v DATESTAMP;
    [ ! -z "${ROLLOVER_CHECK}" ] && unset -v ROLLOVER_CHECK;
    [ ! -z "${FILE_STAT_TIME}" ] && unset -v FILE_STAT_TIME;
    [ ! -z "${ELIGIBLE_FILE}" ] && unset -v ELIGIBLE_FILE;
    [ ! -z "${CURRENT_NUMBER}" ] && unset -v CURRENT_NUMBER;
    [ ! -z "${ADD_NUMBER}" ] && unset -v ADD_NUMBER;
    [ ! -z "${CURRENT_FILE_CKSUM}" ] && unset -v CURRENT_FILE_CKSUM;
    [ ! -z "${ARCHIVE_FILE_CKSUM}" ] && unset -v ARCHIVE_FILE_CKSUM;
    [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
    [ ! -z "${ARCHIVE_NUMBER}" ] && unset -v ARCHIVE_NUMBER;
    [ ! -z "${ARCHIVED_FILE}" ] && unset -v ARCHIVED_FILE;
    [ ! -z "${FILE_STAT_SIZE}" ] && unset -v FILE_STAT_SIZE;
    [ ! -z "${FILE_STAT_SIZE}" ] && unset -v FILE_STAT_SIZE;

    [ ! -z "${ENABLE_VERBOSE}" -a "${ENABLE_VERBOSE}" = "${_TRUE}" ] && set -x || set +x;
    [ ! -z "${ENABLE_TRACE}" -a "${ENABLE_TRACE}" = "${_TRUE}" ] && set -x || set +x;

    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && typeset -i END_EPOCH=$(/usr/bin/env date +"%s");
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && typeset -i RUNTIME=$(( START_EPOCH - END_EPOCH ));
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && writeLogEntry "PERFORMANCE" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} TOTAL RUNTIME: $(( RUNTIME / 60)) MINUTES, TOTAL ELAPSED: $(( RUNTIME % 60)) SECONDS";
    [ ! -z "${ENABLE_PERFORMANCE}" -a "${ENABLE_PERFORMANCE}" = "${_TRUE}" ] && writeLogEntry "PERFORMANCE" "${FUNCTION_NAME}" "${SCRIPT_NAME}" "${LINENO}" "${FUNCTION_NAME} END: $(/usr/bin/env date +"${TIMESTAMP_OPTS}")";

    [ ! -z "${FUNCTION_NAME}" ] && unset -v FUNCTION_NAME;
    [ ! -z "${SCRIPT_NAME}" ] && unset -v SCRIPT_NAME;

    return ${RETURN_CODE};
}

#=====  FUNCTION  =============================================================
#          NAME:  writeLogEntry
#   DESCRIPTION:  Cleans up the archived log directory
#    PARAMETERS:  Archive Directory, Logfile Name, Retention Time
#       RETURNS:  0 regardless of result.
#==============================================================================
function writeLogEntry
{
    set +o noclobber;
    typeset SCRIPT_NAME="logging.sh";
    typeset FUNCTION_NAME="${FUNCNAME[0]}";
    typeset -i COUNTER=0;
    typeset -i RETURN_CODE=0;

    if [ ${#} -eq 0 -a ${#} -ne 5 ]
    then
        typeset RETURN_CODE=3;

        printf "${FUNCTION_NAME} - Write a log message to stdout/err or to a logfile\n" >&2;
        printf "Usage: ${FUNCTION_NAME} [ <level> ] [ <class/script> ] [ <method> ] [ <line> ] [ <message> ]
                 -> The level to write for. Supported levels:
                     STDOUT
                     STDERR
                     PERFORMANCE
                     FATAL
                     ERROR
                     INFO
                     WARN
                     AUDIT
                     DEBUG
                 -> The class/script calling the logger
                 -> The method calling the logger
                 -> The line number making the call
                 -> The message to be printed.\n" >&2;

        return ${RETURN_CODE};
    fi

    typeset LOG_DATE=$(date +"${TIMESTAMP_OPTS}");
    typeset LOG_LEVEL="${1}";
    typeset LOG_SOURCE="${2}";
    typeset LOG_METHOD="${3}";
    typeset LOG_LINE="${4}";
    typeset LOG_MESSAGE="${5}";

    [[ ${LOG_LEVEL} =~ [Ss][Tt][Dd][Oo][Uu][Tt] ]] && printf "%s\n" "${5}" >&1;
    [[ ${LOG_LEVEL} =~ [Ss][Tt][Dd][Ee][Rr][Rr] ]] && printf "%s\n" "${5}" >&2;
    [[ ${LOG_LEVEL} =~ [Pp][Ee][Rr][Ff][Oo][Rr][Mm][Aa][Nn][Cc][Ee]|[Pp] ]] && typeset LOG_FILE="${PERF_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Ff][Aa][Tt][Aa][Ll]|[Ff] ]] && typeset LOG_FILE="${FATAL_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Ee][Rr][Rr][Oo][Rr]|[Ee] ]] && typeset LOG_FILE="${ERROR_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Ww][Aa][Rr][Nn]|[Ww] ]] && typeset LOG_FILE="${WARN_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Ii][Nn][Ff][Oo]|[Ii] ]] && typeset LOG_FILE="${INFO_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Aa][Uu][Dd][Ii][Tt]|[Aa] ]] && typeset LOG_FILE="${AUDIT_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Dd][Ee][Bb][Uu][Gg]|[Dd] ]] && typeset LOG_FILE="${DEBUG_LOG_FILE}";
    [[ ${LOG_LEVEL} =~ [Mm][Oo][Nn][Ii][Tt][Oo][Rr]|[Mm] ]] && typeset LOG_FILE="${MONITOR_LOG_FILE}";

    [ ! -z "${LOG_FILE}" ] && printf "${CONVERSION_PATTERN}\n" "${LOG_DATE}" "${PPID}" "${LOG_FILE}" "${LOG_LEVEL}" "${LOG_SOURCE}" "${LOG_LINE}" "${LOG_METHOD}" "${LOG_MESSAGE}" >> "${LOG_ROOT}/${LOG_FILE}";

    [ ! -z "${LOG_DATE}" ] && unset -v LOG_DATE;
    [ ! -z "${LOG_LEVEL}" ] && unset -v LOG_LEVEL;
    [ ! -z "${LOG_METHOD}" ] && unset -v LOG_METHOD;
    [ ! -z "${LOG_SOURCE}" ] && unset -v LOG_SOURCE;
    [ ! -z "${LOG_LINE}" ] && unset -v LOG_LINE;
    [ ! -z "${LOG_MESSAGE}" ] && unset -v LOG_MESSAGE;
    [ ! -z "${LOG_FILE}" ] && unset -v LOG_FILE;

    return ${RETURN_CODE};
}
