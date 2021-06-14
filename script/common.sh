#!/bin/bash
# docker version: 19.03.3+
# docker-compose version: 1.27.0+

set +e
set -o noglob


# Set Colours
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)  # 关闭所有属性

red=$(tput setaf 1)     # setaf 使用ANSI转义设置前景色
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)


underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
sucess() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}

set -e

function check_nvidia {
    if ! nvidia-smi &> /dev/null
    then
        error "Need to install Nvidia device first and run this script again."
        exit 1
    fi
}

function check_docker {
    if ! docker --version &> /dev/null
    then
        error "Need to install docker(19.03.3+) first and run this script again."
        exit 1
    fi

    # docker has been installed and check its version
    if [[ $(docker --version) =~ (([0-9]+)\.([0-9]+)\.([0-9]*)) ]]
    then
        docker_version=${BASH_REMATCH[1]}
        docker_version_part1=${BASH_REMATCH[2]}
        docker_version_part2=${BASH_REMATCH[3]}
        docker_version_part3=${BASH_REMATCH[4]}

        note "docker version: $docker_version"
        # Determine the Docker version
        if [ "docker_version" -lt 19 ] || ([ "docker_version_part1" -eq 19 ] && [ "docker_version_part2" -lt 3 ] && [ "docker_version_part3" -lt 3 ])
        then
            error "Need to upgrade docker package to 19.03.3+."
            exit 1
        fi
    else
        error "Failed to parse docker version."
        exit 1
    fi
}

function check_dockercompose {
    if ! docker-compose --version &> /dev/null
    then
        error "Need to install docker-compose(1.27.0+) by yourself first and run this script again."
        exit 1
    fi
    # docker-compose has been installed, check its version
    if [[ $(docker-compose --version) =~ (([0-9]+)\.([0-9]+)\.([0-9]*)) ]]
    then
        docker_compose_version=${BASH_REMATCH[1]}
        docker_compose_version_part1=${BASH_REMATCH[2]}
        docker_compose_version_part2=${BASH_REMATCH[3]}

        note "docker-compose version: $docker_compose_version"
        # Determine the docker-compose version
        if [ "$docker_compose_version_part1" -lt 1 ] || ([ "$docker_compose_version_part1" -eq 1 ] && [ "$docker_compose_version_part2" -lt 27 ])
        then
            error "Need to upgrade docker-compose package to 1.27.0+."
            exit 1
        fi
    else
        error "Failed to parse docker-compose version."
        exit 1
    fi
}








