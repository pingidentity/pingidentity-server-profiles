#!/usr/bin/env sh
${VERBOSE} && set -x

# shellcheck disable=SC1090
. "${HOOKS_DIR}/pingcommon.lib.sh"

# shellcheck disable=SC1090
. "${HOOKS_DIR}/pingstate.lib.sh"

hashProfile ()
{
    # shellcheck disable=SC2153
    echo "${1}" | awk -f "${STAGING_DIR}/hash.awk"
}

########################################################################################
# performs a git clone on the server profile passed
########################################################################################
mergeProfile ()
{
    serverProfileUrl=$( get_value "${1}_URL" )
    serverProfileBranch=$( get_value "${1}_BRANCH" )
    serverProfilePath=$( get_value "${1}_PATH" )
    serverProfileGitUserVariable="${1}_GIT_USER"
    serverProfileGitUser=$( get_value "${serverProfileGitUserVariable}" )
    serverProfileGitPasswordVariable="${1}_GIT_PASSWORD"
    serverProfileGitPassword=$( get_value "${serverProfileGitPasswordVariable}" )

    # Get defaults for git user/password if there are no layer-specific values
    if test -z "${serverProfileGitUser}"
    then
        serverProfileGitUserVariable="SERVER_PROFILE_GIT_USER"
        serverProfileGitUser=$( get_value "${serverProfileGitUserVariable}" )
    fi
    if test -z "${serverProfileGitPassword}"
    then
        serverProfileGitPasswordVariable="SERVER_PROFILE_GIT_PASSWORD"
        serverProfileGitPassword=$( get_value "${serverProfileGitPasswordVariable}" )
    fi

    if test -n "${serverProfileGitUser}" || test -n "${serverProfileGitPassword}"
    then
        # Expand user and password in the url
        serverProfileUrl=$( echo "${serverProfileUrl}" | envsubst "\${${serverProfileGitUserVariable}} \${${serverProfileGitPasswordVariable}}" )
        # Redact URL if it includes user/password
        SERVER_PROFILE_URL_REDACT=true
    fi

    # this is a precaution because git clone needs an empty target
    RESTAGING_DIR="/tmp/re-staging"
    test -d "${RESTAGING_DIR}" || mkdir "${RESTAGING_DIR}"


    if test -n "${serverProfileUrl}"
    then
        # deploy configuration if provided
        if test "${SERVER_PROFILE_URL_REDACT}" = "true"
        then
            serverProfileUrlDisplay="*** REDACTED ***"
        else
            serverProfileUrlDisplay="${serverProfileUrl}"
        fi

        _gitCloneStderrFile="/tmp/cloneStderr.txt"
        _restagingPath="${RESTAGING_DIR}/$( hashProfile "${serverProfileUrl}" )"
        if test -d "${_restagingPath}"
        then
            ${VERBOSE_GIT} && echo "Pulling ${1}"
            ${VERBOSE_GIT} && echo "  git url: ${serverProfileUrlDisplay}"
            ${VERBOSE_GIT} && test -n "${serverProfileBranch}" && echo "   branch: ${serverProfileBranch}"
            ${VERBOSE_GIT} && test -n "${serverProfilePath}" && echo "     path: ${serverProfilePath}"
            git -C "${_restagingPath}" pull 2> "${_gitCloneStderrFile}"
            _gitRC=${?}
        else
            ${VERBOSE_GIT} && echo "Cloning ${1}"
            ${VERBOSE_GIT} && echo "  git url: ${serverProfileUrlDisplay}"
            ${VERBOSE_GIT} && test -n "${serverProfileBranch}" && echo "   branch: ${serverProfileBranch}"
            ${VERBOSE_GIT} && test -n "${serverProfilePath}" && echo "     path: ${serverProfilePath}"

            git -C "${_restagingPath}" clone --depth 1 ${serverProfileBranch:+--branch ${serverProfileBranch}} "${serverProfileUrl}" 2> "${_gitCloneStderrFile}"
            _gitRC=${?}
        fi

        if test "${_gitRC}" -ne 0 && test "${SERVER_PROFILE_URL_REDACT}" != "true"
        then
            # Don't show clone error if the URL should be redacted
            cat "${_gitCloneStderrFile}"
        fi
        rm "${_gitCloneStderrFile}"

        _sourceDir="${_gitCloneStderrFile}/${serverProfilePath}/instance"
        if test -d "${_sourceDir}"
        then
            cp -Rf "${_sourceDir}"/. "${SERVER_ROOT_DIR}"
        fi
    else
        ${VERBOSE_GIT} && echo_yellow "INFO: ${1}_URL not set, skipping"
    fi
}

########################################################################################
# takes the current server profile name and appends _PARENT to the end
#   Example: SERVER_PROFILE          returns SERVER_PROFILE_PARENT
#            SERVER_PROFILE_LICENSE  returns SERVER_PROFILE_LICENSE_PARENT
########################################################################################
getParent ()
{
    echo "${serverProfilePrefix}${serverProfileName:+_${serverProfileName}}_PARENT"
}

########################################################################################
# main
serverProfilePrefix="SERVER_PROFILE"
serverProfileName=""
serverProfileParent=$( getParent )
serverProfileList=""

# creates a space separated list of server profiles starting with the parent most
# profile and moving down.
while test -n "$( get_value "${serverProfileParent}" )"
do
    # echo "Profile parent variable: ${serverProfileParent}"
    serverProfileName=$( get_value "${serverProfileParent}" )
    serverProfileLive=$( get_value "${serverProfileUrl}_LIVE" )
    if test -n "${serverProfileLive}" && test "${serverProfileLive}" = "true"
    then
        serverProfileList="${serverProfileName}${serverProfileList:+ }${serverProfileList}"
    fi
    # echo "Profile parent value   : ${serverProfileName}"
    serverProfileParent=$( getParent )
done

# now, take that space separated list of servers and get the profiles for each
# one until exhausted.
while true
do
    for serverProfileName in ${serverProfileList}
    do
        mergeProfile "${serverProfilePrefix}_${serverProfileName}"
    done

    #Finally after all are processed, get the final top level SERVER_PROFILE
    mergeProfile ${serverProfilePrefix}

    # shellcheck disable=SC2086
    sleep ${SERVER_PROFILE_UPDATE_INTERVAL_SECONDS:-30}
done