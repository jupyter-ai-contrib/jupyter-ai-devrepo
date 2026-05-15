# directive: load .env if it exists
set dotenv-load

############################################################################
# Global recipes that work anywhere under this devrepo

sync *args:
    #!/usr/bin/env bash
    refresh_flags=$(sed -n '/\[tool.uv.sources\]/,/^\[/p' pyproject.toml \
        | grep 'workspace = true' \
        | sed 's/ =.*//' \
        | xargs -I{} echo --refresh-package {})
    uv sync $refresh_flags {{args}}

sync-all *args:
    uv sync --extra optional {{args}}

mainline +args:
    #!/usr/bin/env bash
    submodules=$(git submodule foreach -q 'echo $sm_path')
    args=({{args}})
    if [[ "${args[0]}" != "all" ]]; then
        # Syntax: just mainline <submodule> [<submodule>...]
        for mod in "${args[@]}"; do
            echo "$submodules" | grep -qx "$mod" || { echo "Error: '$mod' is not a submodule" >&2; exit 1; }
        done
        just _mainline-run "${args[@]}"
    elif [[ ${#args[@]} -eq 1 ]]; then
        # Syntax: just mainline all
        just _mainline-run $submodules
    elif [[ ${#args[@]} -ge 3 && "${args[1]}" == "-x" ]]; then
        # Syntax: just mainline all -x <submodule> [<submodule>...]
        excludes=("${args[@]:2}")
        for ex in "${excludes[@]}"; do
            echo "$submodules" | grep -qx "$ex" || { echo "Error: '$ex' is not a submodule" >&2; exit 1; }
        done
        modules=()
        for mod in $submodules; do
            skip=false
            for ex in "${excludes[@]}"; do [[ "$mod" == "$ex" ]] && skip=true; done
            $skip || modules+=("$mod")
        done
        just _mainline-run "${modules[@]}"
    else
        echo "Usage:" >&2
        echo "  just mainline <submodule> [<submodule>...]" >&2
        echo "  just mainline all" >&2
        echo "  just mainline all -x <submodule> [<submodule>...]" >&2
        exit 1
    fi

# Internal: switches each module to main and pulls
_mainline-run +modules:
    #!/usr/bin/env bash
    for mod in {{modules}}; do
        echo "Resetting $mod to origin/main..."
        git -C "$mod" switch main -q && git -C "$mod" pull -q
    done
    echo "Done. You may need to run: just sync"

pull-all:
    git submodule foreach -q 'echo $sm_path' | xargs -P 100 -I{} sh -c 'cd {} && git switch main -q && git pull -q'

build-all:
    #!/usr/bin/env bash
    # uv run --project .. ensures we don't create another uv.lock & .venv file in every submodule
    # important: the command passed to `foreach` must use single quotes to allow $name to be accessed
    git submodule foreach '
        if [ -f package.json ]
            then uv run --project .. jlpm && uv run --project .. jlpm build
            else echo "Skipping build in $name as it lacks a package.json file"
        fi;
    '

enable-server-extensions:
    #!/usr/bin/env bash
    # $name := name of submodule in the current iteration
    # ${name//-/_} := name with all '-' chars replaced with '_'
    git submodule foreach '
        # Skip jupyter-chat as it is a special case
        if [ "$name" = "jupyter-chat" ]; then
            exit 0
        fi
        uv run --project .. jupyter server extension enable ${name//-/_}
    '
    # Enable jupyter-chat server extension imperatively
    uv run jupyter server extension enable jupyterlab_chat

enable-lab-extensions:
    #!/usr/bin/env bash
    git submodule foreach '
        # Skip jupyter-chat as it is a special case
        if [ "$name" = "jupyter-chat" ]; then
            exit 0
        fi
        # Only enable labextension if submodule contains package.json
        if [ -f package.json ]
            then uv run --project .. jupyter labextension develop . --overwrite
            else echo "Skipping enabling labextension in $name as it lacks a package.json file"
        fi
    '
    # Enable jupyter-chat lab extension imperatively
    uv run jupyter labextension develop jupyter-chat/python/jupyterlab-chat --overwrite

enable-extensions: enable-server-extensions enable-lab-extensions

install-all: && build-all enable-extensions
    uv sync

uninstall-all:
    rm -rf .venv; exit 0
    rm uv.lock; exit 0

reinstall-all: uninstall-all && install-all

clean:
    -rm *.chat 2>/dev/null
    -rm *.qasm 2>/dev/null
    -rm *.ipynb 2>/dev/null

start *args:
    @# this always runs from the devrepo root
    uv run jupyter lab --config={{justfile_directory()}}/jupyter_server_config.py {{args}}

############################################################################
# Local recipes that only work in a submodule

verify-in-submodule:
    #!/usr/bin/env bash
    cdir={{ invocation_directory() }}
    rootdir={{ justfile_directory() }}

    # exit early if not in submodule
    relative="${cdir#$rootdir/}"
    if [[ "$relative" == "$cdir" ]]; then
        echo "just build must be run in a submodule"
        exit 1
    fi

jlpm *args: verify-in-submodule
    #!/usr/bin/env bash
    cd {{ invocation_directory() }}
    uv run --project {{ justfile_directory() }} jlpm {{args}}

build: verify-in-submodule
    #!/usr/bin/env bash
    cd {{ invocation_directory() }}
    uv run --project {{ justfile_directory() }} jlpm build

lint: verify-in-submodule
    #!/usr/bin/env bash
    cd {{ invocation_directory() }}
    uv run --project {{ justfile_directory() }} jlpm lint

pytest: verify-in-submodule
    #!/usr/bin/env bash
    cd {{ invocation_directory() }}
    uv run --project {{ justfile_directory() }} pytest

reinstall: verify-in-submodule
    #!/usr/bin/env bash
    uv sync
    source {{ justfile_directory() }}/.venv/bin/activate
    cd {{ invocation_directory() }}
    pip install -e .
    deactivate
