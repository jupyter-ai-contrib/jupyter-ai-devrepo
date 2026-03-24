# jupyter-ai-devrepo

An experimental "developer repo" intended for Jupyter AI contributors.

By cloning the repo and following the steps below, you can have an editable
developer installation of all Jupyter AI subpackages.

## Getting started

### 0. Clone the repo

```
git clone --recurse-submodules <url>
cd jupyter-ai-devrepo/
```

### 1. Install root dependencies

This monorepo requires `git`, `uv`, and `just`.

No dedicated Python environment is required because `uv` automatically manages a
local venv.

If you use `conda`/`mamba`/`micromamba`, you can run the following commands to
install these dependencies into the `base` environment:

```sh
{conda,mamba,micromamba} activate base
{conda,mamba,micromamba} install uv just
# make sure to activate the `base` environment before working in this repo
```

Otherwise, you can use your OS's package manager. For example, on macOS:

```sh
brew install uv just
```

### 2. Pull in latest changes

This command switches to the `main` branch on every submodule and pulls from it.

```
just pull-all
```

### 3. Install all packages

This command automatically installs each of the packages in editable mode.

```
just install-all
```

### 4. Start JupyterLab

Start JupyterLab by running:

```
just start
```

This command will always run `uv run jupyter lab` from the root of this devrepo,
even if your current directory is inside of a submodule.

## Development guide

Every submodule under this repository can be treated as a normal git repository
once entered. For example, `git pull`, `git remote add ...`, and `git push` work
as you would expect after running `cd jupyter-ai-acp-client/`.

In development workflows, there are 4 actions you will perform frequently:

- *After editing frontend files in a submodule,* run `just build` (**not** `jlpm
build`) to re-build the frontend assets in that submodule. You can then refresh
the JupyterLab page in the browser to view the new changes.

- *After editing any backend files*, restart the JupyterLab server for the
changes to take effect.

- *After editing the `pyproject.toml` file in a submodule*, run `just reinstall`.
This applies any changes to the dependency tree and makes new entry points
available. This also requires restarting the JupyterLab server.

- *Before opening a PR for a submodule*, you will want to run `just lint` and
`just pytest` to ensure lint & test checks pass.

## Command reference

**Global commands** that work anywhere under `jupyter-ai-devrepo/`:

- `just start`: start JupyterLab

    - `Ctrl + Z` + `kill -9 %1` stops JupyterLab in case `Ctrl + C` does not work

- `just clean`: remove all `*.{chat,ipynb}` files from the top-level directory

- `just sync`: run `uv sync`

  - Required when adding/removing any dependencies to this devrepo or its
  submodules. This is run automatically by all `uv` commands so it is usually
  not necessary.

  - Pass `--refresh` if `uv sync` fails with: "No solution found when resolving
  dependencies for split — we can conclude that your workspace's requirements
  are unsatisfiable."

- `just sync-all`: run `uv sync --extra optional`

  - Installs optional submodules (`jupyter_ai_litellm`,
  `jupyter_ai_jupyternaut`, `jupyter_ai_magic_commands`) in addition to the
  required ones.

  - Also accepts extra flags, e.g. `just sync-all --refresh`.

- `just pull-all`: switch to `main` in all submodules and pull in all upstream changes

- `just build-all`: build all frontend assets in every submodule

- `just install-all`: perform an editable, developer installation of all packages

- `just uninstall-all`: delete the virtual environment

- `just reinstall-all`: equivalent to `just uninstall-all && just install-all` (useful for fixing a broken venv)

**Local commands** that only work under a submodule (e.g. `jupyter-ai-devrepo/jupyter-ai-acp-client`):

- `just build`: build the frontend assets in the current submodule (equivalent to `jlpm build`).

    - Required when updating frontend assets in a submodule.

- `just reinstall`: re-install the current submodule as a Python package in the virtual environment.

    - Required when updating the `pyproject.toml` file in a submodule.

- `just pytest`: run `pytest` in the current submodule.