# DMS AI Assistant — development tasks

plugin_name := "AIAssistant"
plugin_dir  := env("HOME") / ".config/DankMaterialShell/plugins" / plugin_name
repo_root   := justfile_directory()

# List available recipes
default:
    @just --list

# Run qmllint on all QML files (or specific files)
lint *files:
    {{repo_root}}/scripts/lint.sh {{files}}

# Generate qmllint module stubs from DMS installation
setup-lint:
    {{repo_root}}/scripts/setup-qmllint.sh

# Install plugin by copying to DMS plugins directory
install:
    mkdir -p "$(dirname '{{plugin_dir}}')"
    rm -rf '{{plugin_dir}}'
    rsync -a --exclude='.git' --exclude='.qmllint' --exclude='screenshots' '{{repo_root}}/' '{{plugin_dir}}/'
    @echo "Installed to {{plugin_dir}}"

# Restart DMS to reload plugin changes
restart:
    dms restart

# Install plugin and restart DMS
deploy: install restart
