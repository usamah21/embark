#!/usr/bin/env bash

reset_shim_demo() {
    local EMBARK_DOCKER_IMAGE="${EMBARK_DOCKER_IMAGE:-statusim/embark}"
    local EMBARK_DOCKER_TAG="${EMBARK_DOCKER_TAG:-shim-demo}"
    local step
    if [[ -z "$1" ]]; then
        step="step-0"
    else
        step="$1"
    fi
    docker rmi "${EMBARK_DOCKER_IMAGE}:${EMBARK_DOCKER_TAG}-${step}" &> /dev/null
}
export -f reset_shim_demo

run_shim_demo () {
    local EMBARK_BRANCH="${EMBARK_BRANCH:-features/global-local-cmd-shim}"
    local EMBARK_DOCKER_IMAGE="${EMBARK_DOCKER_IMAGE:-statusim/embark}"
    local EMBARK_DOCKER_RUN
    local EMBARK_DOCKER_RUN_INTERACTIVE
    local EMBARK_DOCKER_RUN_OPTS_REPLACE
    local EMBARK_DOCKER_RUN_RM
    local EMBARK_DOCKER_TAG="${EMBARK_DOCKER_TAG:-shim-demo}"
    local embark_docker_tag="$EMBARK_DOCKER_TAG"
    local EMBARK_DOCKERFILE="${EMBARK_DOCKERFILE:-https://github.com/embark-framework/embark-docker.git#master}"
    # ^ for local override spec with /path/to/embark-docker/
    local EMBARK_SHIM_DEMO_DEV=${EMBARK_SHIM_DEMO_DEV:-false}
    local EMBARK_VERSION="${EMBARK_VERSION:-embark-framework/embark#${EMBARK_BRANCH}}"
    local REAL="${REAL:-https://gist.githubusercontent.com/michaelsbradleyjr/87b5a99ad551e04cbad9c0c1d3af412b/raw/bfec2e589a91302b30f1d7cac8c2df71e5ebabe0/real.sh}"
    local RUNNER="${RUNNER:-https://raw.githubusercontent.com/embark-framework/embark-docker/master/run.sh}"
    # ^ for local override spec URL with file:///path/to/run.sh
    local work_dir="$PWD"

    check_image () {
        local tag
        if [[ -z "$1" ]]; then
            tag=$EMBARK_DOCKER_TAG
        else
            tag="${embark_docker_tag}-$1"
        fi
        local iid="$(docker images -q ${EMBARK_DOCKER_IMAGE}:${tag} 2> /dev/null)"
        if [[ "$iid" = "" ]]; then
            return 1
        fi
    }

    local was_reset=false

    # -- step 0 ----------------------------------------------------------------

    echo '-----------------------------------'
    echo 'STEP 0'
    echo '-----------------------------------'

    EMBARK_DOCKER_TAG=${embark_docker_tag}-step-0
    if ! check_image; then
        was_reset=true
        docker build \
               --build-arg EMBARK_VERSION=$EMBARK_VERSION \
               -t $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG \
               $EMBARK_DOCKERFILE
    else
        echo "cached..."
    fi

    source <(curl "$REAL" 2> /dev/null)
    local script_dir="$(real_dir "$BASH_SOURCE")"
    local embark_dir="$(real_dir "$script_dir/../..")"
    local cid_file="$script_dir/.cid"

    source <(curl "$RUNNER" 2> /dev/null)

    # -- step 1 ----------------------------------------------------------------

    echo '-----------------------------------'
    echo 'STEP 1'
    echo '-----------------------------------'

    if (! check_image step-1) || [[ $was_reset = true ]]; then
        was_reset=true
        rm -rf "$cid_file"
        run_embark \
            --cidfile "$cid_file" \
            -d \
            -- bash -c 'trap "exit 0" SIGINT && while true; do sleep 1; done'
        docker exec \
               -it \
               $(cat "$cid_file") \
               bash -c 'apt-get update && apt-get install -y rsync'
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-1
        docker commit \
               --pause \
               $(cat "$cid_file") \
               $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG
        docker stop $(cat "$cid_file")
        rm -rf "$cid_file"
    else
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-1
        echo "cached..."
    fi

    # -- step 2 ----------------------------------------------------------------

    echo '-----------------------------------'
    echo 'STEP 2'
    echo '-----------------------------------'

    local td="$(mktemp -d)"
    local td_dapp="${HOME}/temp/$(basename $(mktemp -d))"
    mkdir -p "$td_dapp"

    if (! check_image step-2) || [[ $was_reset = true ]]; then
        was_reset=true
        rm -rf "$cid_file"
        # do not alter indentation, tabs in lines below
        cat <<- 'SCRIPT' > "$td/step_2.sh"
	simple_nodeenv 8.11.2 pre-lts-newer-npm
	npm install -g npm@6.2.0
	simple_nodeenv 8.11.3 lts-older-npm
	simple_nodeenv 8.11.3 lts
	npm install -g npm@6.2.0
	SCRIPT
        # do not alter indentation, tabs in lines above
        cd "$td_dapp"
        EMBARK_DOCKER_RUN="$td/step_2.sh"
        EMBARK_DOCKER_RUN_RM=false
        run_embark --cidfile "$cid_file" --
        EMBARK_DOCKER_RUN=
        EMBARK_DOCKER_RUN_RM=true
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-2
        docker commit $(cat "$cid_file") $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG
        docker rm $(cat "$cid_file")
        rm -rf "$cid_file"
        cd "$work_dir"
    else
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-2
        echo "cached..."
    fi

    # -- step 3 ----------------------------------------------------------------

    echo '-----------------------------------'
    echo 'STEP 3'
    echo '-----------------------------------'

    if (! check_image step-3) || [[ $was_reset = true ]]; then
        was_reset=true
        rm -rf "$cid_file"
        # do not alter indentation, tabs in lines below
        cat <<- 'SCRIPT' > "$td/step_3.sh"
	dev=$1
	embark_branch="$2"
	if [[ "$dev" = false ]]; then
	    mkdir -p ~/repos/embark
	    git clone https://github.com/embark-framework/embark.git \
	              ~/repos/embark
	    cd ~/repos/embark \
	        && git checkout "$embark_branch" \
	        && cd - &> /dev/null
	fi
	mkdir -p ~/working/embark
	rsync -a \
	      --exclude=.git \
	      --exclude=node_modules \
	      ~/repos/embark \
	      ~/working/
	cd ~/working/embark
	nac lts
	npm install
	npm link \
	cd - &> /dev/null
	SCRIPT
        # do not alter indentation, tabs in lines above
        cd "$td_dapp"
        EMBARK_DOCKER_RUN="$td/step_3.sh"
        EMBARK_DOCKER_RUN_RM=false
        local -a run_opts_step_3=(
            "--cidfile"
            "$cid_file"
        )
        if [[ $EMBARK_SHIM_DEMO_DEV = true ]]; then
            run_opts_step_3=(
                "${run_opts_step_3[@]}"
                "-v"
                "${embark_dir}:/home/embark/repos/embark"
            )
        fi
        run_embark "${run_opts_step_3[@]}" \
                   -- \
                   $EMBARK_SHIM_DEMO_DEV \
                   "$EMBARK_BRANCH"
        EMBARK_DOCKER_RUN=
        EMBARK_DOCKER_RUN_RM=true
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-3
        docker commit $(cat "$cid_file") $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG
        docker rm $(cat "$cid_file")
        rm -rf "$cid_file"
        cd "$work_dir"
    else
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-3
        echo "cached..."
    fi

    # -- step 4 ----------------------------------------------------------------

    echo '-----------------------------------'
    echo 'STEP 4'
    echo '-----------------------------------'

    if (! check_image step-4) || [[ $was_reset = true ]]; then
        was_reset=true
        rm -rf "$cid_file"
        # do not alter indentation, tabs in lines below
        cat <<- 'SCRIPT' > "$td/step_4.sh"
	dev=$1
	if [[ "$dev" = true ]]; then
	    rsync -a \
	          --exclude=.git \
	          --exclude=node_modules \
	          ~/repos/embark \
	          ~/working/
	fi
	cd ~
	nac lts
	embark demo
	cd - &> /dev/null
	SCRIPT
        # do not alter indentation, tabs in lines above
        cd "$td_dapp"
        EMBARK_DOCKER_RUN="$td/step_4.sh"
        EMBARK_DOCKER_RUN_RM=false
        local -a run_opts_step_4=(
            "--cidfile"
            "$cid_file"
        )
        if [[ $EMBARK_SHIM_DEMO_DEV = true ]]; then
            run_opts_step_4=(
                "${run_opts_step_4[@]}"
                "-v"
                "${embark_dir}:/home/embark/repos/embark"
            )
        fi
        run_embark "${run_opts_step_4[@]}" \
                   -- \
                   $EMBARK_SHIM_DEMO_DEV
        EMBARK_DOCKER_RUN=
        EMBARK_DOCKER_RUN_RM=true
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-4
        docker commit $(cat "$cid_file") $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG
        docker rm $(cat "$cid_file")
        rm -rf "$cid_file"
        cd "$work_dir"
    else
        EMBARK_DOCKER_TAG=${embark_docker_tag}-step-4
        echo "cached..."
    fi

    # -- step 5 ----------------------------------------------------------------

    echo '-----------------------------------'
    echo 'STEP 5'
    echo '-----------------------------------'

    # do not alter indentation, tabs in lines below
    cat <<- 'SCRIPT' > "$td/step_5.sh"
	dev=$1
	if [[ "$dev" = true ]]; then
	    rsync -a \
	          --exclude=.git \
	          --exclude=node_modules \
	          ~/repos/embark \
	          ~/working/
	fi
	cd ~
	declare -a messages=(
	    "What's the output of ls embark_demo?"
	    "What's the version of node?"
	    "What's the version of npm?"
	)
	export txtbld=$(tput bold)
	export txtrst=$(tput sgr0)
	export bldcyn=${txtbld}$(tput setaf 6)
	say () {
	    echo
	    echo
	    echo ${bldcyn}"$1"${txtrst}
	    echo
	}
	export -f say
	bash -is "${messages[@]}" << 'DEMO'
	PROMPT_COMMAND="echo"
	say "$1"
	ls embark_demo
	say "$2"
	node --version
	say "$3"
	npm --version
	DEMO
	trap "exit 0" SIGINT && while true; do sleep 1; done
	SCRIPT
    # do not alter indentation, tabs in lines above
    cd "$td_dapp"
    EMBARK_DOCKER_RUN="$td/step_5.sh"
    local -a run_opts_step_5=()
    if [[ $EMBARK_SHIM_DEMO_DEV = true ]]; then
        run_opts_step_5=(
            "${run_opts_step_5[@]}"
            "-v"
            "${embark_dir}:/home/embark/repos/embark"
        )
    fi
    run_embark "${run_opts_step_5[@]}" \
               -- \
               $EMBARK_SHIM_DEMO_DEV
    EMBARK_DOCKER_RUN=
    cd "$work_dir"
    unset check_image
}
export -f run_shim_demo

if [[ "$0" = "$BASH_SOURCE" ]]; then
    run_shim_demo
fi
