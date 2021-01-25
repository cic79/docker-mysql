#!/usr/bin/env bash

function confirm {
    # Call with a prompt string or use a default.
    # Usage:
    #   confirm && hg push ssh://..
    # or
    #   confirm "Would you really like to do a push?" && hg push ssh://..
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

function usage {
    echo "Usage: $0 [OPTION]..."
    echo "Setup the docker and/or start the containers."
    echo ""
    echo "  -b, --bash               Connect to bash in django with user prototype"
    echo "  -l, --logs [SERVICE]     View output from containers (SERVICE is optional)"
    echo "  -i, --init               Build or rebuild services, create and start containers"
    echo "  -x, --run                Create and start containers"
    echo "  -s, --stop [SERVICE]     Stop and remove containers, networks, volumes and images (SERVICE is optional)"
    echo "  -r, --restart [SERVICE]  Stop and start services (SERVICE is optional)"
    echo "  -u, --update             Update the docker-compose to the last version"
    echo "  -p, --prune [BRANCH]     Purge all containers, volumes, networks, images and SAVE dirs or a specific BRANCH"
    echo "  -h, --help               Display this help and exit"
    echo ""
}

function bash {
    docker exec -it --user prototype prototype_django bash
}

function logs {
    if [[ "$1" == "" ]]; then
        docker-compose logs -f --tail=10
    else
        docker-compose logs -f --tail=10 "$1"
    fi
}

function permissions {
    # Set permissions for the mysql dir
    mkdir -p mysql/SAVE
    sudo chmod -R 777 mysql/SAVE/*
    mkdir -p /tmp/jinja_cache
}

function build {
    # Build or rebuild services, create and start containers
    permissions
    # shellcheck disable=SC2086
    docker-compose build ${SERVICES}
    run
}

function run {
    # Create and start containers
    permissions
    branch="$(basename "$(git symbolic-ref HEAD)")"
    sed -i -e "s/BRANCH_NAME=.*/BRANCH_NAME=$branch/g" .env
    # shellcheck disable=SC2086
    docker-compose up -d ${SERVICES}
    docker-compose ps
}

function stop {
    if [[ "$1" == "" ]]; then
        # Stop and remove containers, networks, images, and volumes
        docker-compose rm -f -s
        docker network prune -f
    else
        # Stop and remove containers, networks, images, and volumes
        docker-compose rm -f -s "$1"
    fi
}

function restart {
    if [[ "$1" == "" ]]; then
        stop
        run
    else
        docker-compose restart "$1"
    fi
}

function update {
    # Update docker-compose
    sudo curl -L "$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep "$(uname -s)-$(uname -m)" | grep -i -v sha256 | awk '/browser_download_url/ { print $2 }' | sed 's/"//g')" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    # docker-compose command-line completion
    sudo curl -L "https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose
    docker-compose --version
}

function prune {
    stop
    # Prune all datas
    confirm "WARNING! This will remove:
	- all stopped containers
	- all volumes not used by at least one container
	- all networks not used by at least one container
	- all images without at least one container associated to them
Are you sure you want to continue? [y/N]" && docker system prune -a -f && docker volume prune
    if [[ "$1" == "" ]]; then
        confirm "WARNING! This will remove all SAVE directories
Are you sure you want to continue? [y/N]" && (sudo find . -name "SAVE" -type d -exec sudo rm -rf "{}" \; > /dev/null 2>&1)
    else
        confirm "WARNING! This will remove all SAVE/$1 directories
Are you sure you want to continue? [y/N]" && (sudo find . -name "$1" -type d | grep SAVE | xargs sudo rm -rf > /dev/null 2>&1)
    fi
}


# Change to script dir
CURRENT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}" )")" && pwd)"
cd "${SCRIPT_DIR}"

# Get default services to start from .env
SERVICES=$(grep SERVICES .env | cut -d '=' -f2)

if [[ "$1" == "" ]]; then
    usage
else
    while [[ "$1" != "" ]]; do
        case $1 in
            -b | --bash )           bash
                                    ;;
            -l | --logs )           logs "$2"
                                    shift
                                    ;;
            -i | --init )           build
                                    ;;
            -x | --run )            run
                                    ;;
            -s | --stop )           stop "$2"
                                    shift
                                    ;;
            -r | --restart )        restart "$2"
                                    shift
                                    ;;
            -u | --update )         update
                                    ;;
            -p | --prune )          prune "$2"
                                    shift
                                    ;;
            -h | --help )           usage
                                    ;;
            * )                     echo "$0: invalid option -- '$1'"
                                    echo "Try '$0 --help' for more information."
                                    cd "${CURRENT_DIR}"
                                    exit 1
        esac
        shift
    done
fi

cd "${CURRENT_DIR}"
