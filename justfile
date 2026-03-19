############################################################################
# Global recipes that work anywhere under this devrepo

sync:
    uv sync

pull-all:
    git submodule foreach "git switch main && git pull"

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
        # Skip jupyter-ai-claude-code as it is not an extension
        if [[ $name == "jupyter-ai-claude-code" ]]
            then exit 0
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

start:
    @# this always runs from the devrepo root
    uv run jupyter lab

############################################################################
# Local recipes that only work in a submodule

verify-in-submodule:
    #!/usr/bin/env bash
    cdir={{invocation_directory()}}
    rootdir={{justfile_directory()}}

    # exit early if not in submodule
    relative="${cdir#$rootdir/}"
    if [[ "$relative" == "$cdir" ]]; then
        echo "just build must be run in a submodule"
        exit 1
    fi

build: verify-in-submodule
    #!/usr/bin/env bash
    cd {{invocation_directory()}}
    uv run --project {{justfile_directory()}} jlpm build

lint: verify-in-submodule
    #!/usr/bin/env bash
    cd {{invocation_directory()}}
    uv run --project {{justfile_directory()}} jlpm lint

pytest: verify-in-submodule
    #!/usr/bin/env bash
    cd {{invocation_directory()}}
    uv run --project {{justfile_directory()}} pytest

reinstall: verify-in-submodule
    #!/usr/bin/env bash
    uv sync
    source {{justfile_directory()}}/.venv/bin/activate
    cd {{invocation_directory()}}
    pip install -e .
    deactivate
