# DMS AI Assistant — development tasks

plugin_name := "AIAssistant"
plugin_dir  := env("HOME") / ".config/DankMaterialShell/plugins" / plugin_name
repo_root   := justfile_directory()

# List available recipes
default:
    @just --list

# Run qmllint on all QML files (or specific files), then Prettier check on JS
lint *files:
    {{repo_root}}/scripts/lint.sh {{files}}
    npm run lint:prettier --prefix {{repo_root}}

# Auto-format JS/JSON/Markdown files with Prettier
format:
    npm run format:prettier --prefix {{repo_root}}

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

# Build markdown2html.js from source
build:
    npm run build:markdown

# Watch and rebuild markdown2html.js on changes
watch:
    npm run watch:markdown

# Clean generated files
clean:
    npm run clean

# Run plugin
run:
    dms ipc call plugins toggle aiAssistant