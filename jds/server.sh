#!/usr/bin/env bash
#
# Description: A comprehensive script to manage the server.
#
# Modified by: honeok <honeok@duck.com>
#
# Archive on GitHub: https://github.com/honeok/archive/raw/master/jds/server.sh

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$@${white}"; }
_red() { echo -e "${red}$@${white}"; }
_green() { echo -e "${green}$@${white}"; }
_info_msg() { echo -e "\033[48;5;220m\033[1m提示${white}$@"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white}$@"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white}$@"; }

app_name_path="$(cd "$(dirname "$0")" && ls *app_server)"
app_name="$(basename "$app_name_path")"

running() {
    [ -f "pid.txt" ] && [ -f "/proc/$(<pid.txt)/comm" ] && [ "$(cat /proc/$(<pid.txt)/comm)" == "${app_name}" ] && return 0 || return 1
}

start() {
    if ! running >/dev/null 2>&1; then
        ulimit -c unlimited
        nohup "$app_name_path" > nohup.txt 2>&1 &
        echo $! > pid.txt
        _suc_msg "$(_green "server started: $(<pid.txt)")"
    else
        _info_msg "$(_yellow "server is already running: $(<pid.txt)")"
    fi
}

stop() {
    if running >/dev/null 2>&1; then
        kill -SIGKILL "$(<pid.txt)"
        _suc_msg "$(_green "server stop: $(<pid.txt)")"
        rm -f pid.txt
    else
        _err_msg "$(_yellow 'server is not running')"
    fi
}

reload() {
    if running >/dev/null 2>&1; then
        kill -SIGUSR1 "$(<pid.txt)"
        _suc_msg "$(_green "server reload: $(<pid.txt)")"
    else
        _err_msg "$(_yellow 'server is not running')"
    fi
}

flush() {
    if running >/dev/null 2>&1; then
        kill -SIGUSR2 "$(<pid.txt)"
        _suc_msg "$(_green "server flush: $(<pid.txt)")"
    else
        _err_msg "$(_yellow 'server is not running')"
    fi
}

status() {
    if running >/dev/null 2>&1; then
        _suc_msg "$(_green "server running: $(<pid.txt)")"
    else
        _info_msg "$(_yellow 'server is stopped')"
    fi
}

main() {
    case $1 in
        [Ss][Tt][Aa][Rr][Tt]) start ;;
        [Ss][Tt][Oo][Pp]) stop ;;
        [Rr][Ee][Ss][Tt][Aa][Rr][Tt]) stop; start ;;
        [Rr][Ee]|[Rr][Ee][Ll][Oo][Aa][Dd]) reload ;;
        [Ff][Ll]|[Ff][Ll][Uu][Ss][Hh]) flush ;;
        [Ss][Tt][Aa][Tt][Uu][Ss]) status ;;
        *) _info_msg "Usage: ./server.sh start | stop | restart | reload | flush | status" ;;
    esac
}

main "$@"