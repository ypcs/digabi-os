#!/bin/sh
#set -e

DEFAULT="92"
HIDPI="192"
TIMEOUT="15"

ZENITY="/usr/bin/zenity"
XFCONF="/usr/bin/xfconf-query"

[ ! -x "${XFCONF}" ] && echo "E: xfconf-query not found!" && exit 1
[ ! -x "${ZENITY}" ] && echo "E: zenity not found!" && exit 1

CURRENT="$(${XFCONF} -c xsettings -p /Xft/DPI || echo ${DEFAULT})"
[ -z "${CURRENT}" ] && CURRENT="${DEFAULT}"

if [ "${CURRENT}" = "${DEFAULT}" ]
then
    NEW="${HIDPI}"
else
    NEW="${DEFAULT}"
fi

case "${LANG}"
in
    fi*)
        QUESTION="Haluatko säilyttää nykyisen asetuksen?"
    ;;
    sv*)
        QUESTION="Vill du behålla den nuvarande inställningen?"
    ;;
    *)
        QUESTION="Do you want to keep the current setting?"
    ;;
    
esac

echo "I: Set DPI to ${NEW} (was: ${CURRENT})"
${XFCONF} -n -c xsettings -p /Xft/DPI -t int -s ${NEW}
${ZENITY} --question --text "${QUESTION}" --timeout "${TIMEOUT}" 2>/dev/null

if [ $? != 0 ]
then
    echo "I: User asked to return previous value..."
    ${XFCONF} -n -c xsettings -p /Xft/DPI -t int -s ${CURRENT}
fi

exit 0
