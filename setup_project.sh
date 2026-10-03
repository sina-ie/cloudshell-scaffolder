#!/usr/bin/env bash
# ==============================================================================
# Script Name: setup_project.sh
# Description: Automates project scaffolding, Git repository initialization,
#              VS Code configuration, CI pipeline creation, and GitHub remote
#              repository publishing (tailored for Cloud Shell and local envs).
# Usage:       ./setup_project.sh [PROJECT_NAME] [-t pip|pyproject] [--uv] [--public|--private]
# Examples:    ./setup_project.sh my-awesome-app
#              ./setup_project.sh -n my-awesome-app -t pyproject
#              ./setup_project.sh -n my-fast-app -t pyproject --uv --public
# ==============================================================================

set -Eeuo pipefail

REPO_NAME="my-app"
PROJECT_TYPE="pip"
USE_UV=false
VISIBILITY="private"

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)
            REPO_NAME="$2"
            shift 2
            ;;
        -t|--type)
            case "$2" in
                pip|pyproject)
                    PROJECT_TYPE="$2"
                    ;;
                *)
                    echo "Error: Invalid project type '$2'. Allowed values: pip, pyproject" >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --public)
            VISIBILITY="public"
            shift
            ;;
        --private)
            VISIBILITY="private"
            shift
            ;;
        -u|--uv)
            USE_UV=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [PROJECT_NAME] [-n NAME] [-t pip|pyproject] [--uv] [--public|--private]"
            exit 0
            ;;
        *)
            # Positional fallback for REPO_NAME
            REPO_NAME="$1"
            shift
            ;;
    esac
done

PROJECT_DIR="${HOME}/${REPO_NAME}"
echo "==> Scaffolding '${REPO_NAME}' (${VISIBILITY}) using type '${PROJECT_TYPE}' (uv: ${USE_UV})..."

if [[ -d "${PROJECT_DIR}" ]] && [[ -n "$(ls -A "${PROJECT_DIR}" 2>/dev/null)" ]]; then
    echo "Error: Target directory '${PROJECT_DIR}' already exists and is not empty." >&2
    exit 1
fi

echo "==> Step 1: Checking GitHub CLI availability and authentication..."
if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI ('gh') is not installed. Please install it first." >&2
    exit 1
fi

if [[ "${USE_UV}" == "true" ]] && ! command -v uv >/dev/null 2>&1; then
    echo "Error: 'uv' is requested but not installed. Please install it first (e.g., curl -LsSf https://astral.sh/uv/install.sh | sh)." >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub authentication not detected. Initiating web login flow:"
    gh auth login -w -p https
fi

echo "==> Step 2: Creating project directory structure at: ${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}"/{src,tests,.vscode,.github/workflows}
cd "${PROJECT_DIR}"

git init -b main

# Configure Git user details using GitHub profile, fallback if unset/null
GIT_USER_NAME="$(gh api user --jq 'select(.name != null and .name != "") | .name' 2>/dev/null || true)"
GIT_USER_EMAIL="$(gh api user --jq 'select(.email != null and .email != "") | .email' 2>/dev/null || true)"

git config user.name "${GIT_USER_NAME:-Developer}"
git config user.email "${GIT_USER_EMAIL:-dev@example.com}"

# Generate .gitignore
cat << 'GITIGNORE' > .gitignore
# Python byte-compiled / optimized files
__pycache__/
*.pyc
*.pyo
*.pyd

# Environments
.env
.venv/
env/

# Distribution / packaging
dist/
build/
*.egg-info/

# Logs and OS artifacts
*.log
.DS_Store
node_modules/
GITIGNORE

# Generate README.md
cat << README > README.md
# ${REPO_NAME}

Project repository scaffolded for development and deployment in Google Cloud Shell.

## Directory Structure

\`\`\`text
├── .github/workflows/   # CI/CD automation workflows
├── .vscode/             # Editor tasks and debugger configurations
├── src/                 # Application source code
│   └── main.py          # Application entrypoint
├── tests/               # Unit and integration test suites
│   └── test_main.py     # Starter test suite
├── .gitignore           # Git ignore definitions
├── README.md            # Project documentation
└── $([ "${PROJECT_TYPE}" = "pyproject" ] && echo "pyproject.toml     # PEP 621 project configuration" || echo "requirements.txt     # Python project dependencies")
\`\`\`

## Getting Started

### Environment Setup
Activate the virtual environment:
\`\`\`bash
source .venv/bin/activate
\`\`\`

### Execution
Run the application:
- Open the file in the editor and press **F5** (or choose **Run Current File** from the **Run and Debug** menu).
- Alternatively, execute from the terminal:
  \`\`\`bash
  python3 src/main.py
  \`\`\`

### Testing
Run test suites:
\`\`\`bash
pytest
\`\`\`
README

# Generate sample entrypoint in src/main.py
cat << 'CODE' > src/main.py
#!/usr/bin/env python3
"""Application entrypoint module."""

import sys

def main() -> None:
    """Execute primary application logic."""
    print("Application executed successfully from the workspace environment!")
    print(f"Active Python runtime version: {sys.version.split()[0]}")

if __name__ == "__main__":
    main()
CODE
chmod +x src/main.py

# Generate starter test suite in tests/test_main.py
cat << 'TEST' > tests/test_main.py
"""Starter unit test suite."""

from src.main import main

def test_main(capsys) -> None:
    """Verify that main executes and prints the expected greeting."""
    main()
    captured = capsys.readouterr()
    assert "Application executed successfully" in captured.out
TEST

# Configure VS Code launch options
cat << 'LAUNCH' > .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Run Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal"
        },
        {
            "name": "Python: Debug Tests",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": ["tests"],
            "console": "integratedTerminal"
        }
    ]
}
LAUNCH

# Configure VS Code settings to bind to the virtual environment
cat << 'SETTINGS' > .vscode/settings.json
{
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
    "python.testing.unittestEnabled": false,
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": ["tests"]
}
SETTINGS

# Generate project manifest based on selected PROJECT_TYPE
if [[ "${PROJECT_TYPE}" == "pyproject" ]]; then
cat << PYPROJECT > pyproject.toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "${REPO_NAME}"
version = "0.1.0"
description = "Workspace project scaffolded in Cloud Shell"
readme = "README.md"
requires-python = ">=3.11"
dependencies = [
    "pytest>=8.0.0",
]

[tool.hatch.build.targets.wheel]
packages = ["src"]
PYPROJECT
else
cat << 'REQUIREMENTS' > requirements.txt
# Core dependencies
pytest>=8.0.0
REQUIREMENTS
fi

# Configure VS Code tasks
cat << 'TASKS' > .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run main.py",
            "type": "shell",
            "command": "${workspaceFolder}/.venv/bin/python ${workspaceFolder}/src/main.py",
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Run pytest",
            "type": "shell",
            "command": "${workspaceFolder}/.venv/bin/pytest",
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        }
    ]
}
TASKS

# Determine CI installation command based on project type
if [[ "${PROJECT_TYPE}" == "pyproject" ]]; then
    CI_INSTALL_CMD_PIP="pip install -e ."
    CI_INSTALL_CMD_UV="uv pip install --system -e ."
else
    CI_INSTALL_CMD_PIP="pip install -r requirements.txt"
    CI_INSTALL_CMD_UV="uv pip install --system -r requirements.txt"
fi

# Generate default GitHub Actions CI workflow
if [[ "${USE_UV}" == "true" ]]; then
cat << WORKFLOW > .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install uv
        uses: astral-sh/setup-uv@v5
        with:
          enable-cache: true
      - name: Set up Python
        run: uv python install 3.11
      - name: Install dependencies
        run: ${CI_INSTALL_CMD_UV}
      - name: Run entrypoint
        run: uv run python src/main.py
      - name: Run tests
        run: uv run pytest
WORKFLOW
else
cat << WORKFLOW > .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          ${CI_INSTALL_CMD_PIP}
      - name: Run entrypoint
        run: python src/main.py
      - name: Run tests
        run: pytest
WORKFLOW
fi

echo "==> Step 3: Creating virtual environment and installing dependencies..."
if [[ "${USE_UV}" == "true" ]]; then
    uv venv "${PROJECT_DIR}/.venv"
    if [[ "${PROJECT_TYPE}" == "pyproject" ]]; then
        uv pip install --python "${PROJECT_DIR}/.venv/bin/python" -e "${PROJECT_DIR}"
    else
        uv pip install --python "${PROJECT_DIR}/.venv/bin/python" -r "${PROJECT_DIR}/requirements.txt"
    fi
else
    python3 -m venv "${PROJECT_DIR}/.venv"
    "${PROJECT_DIR}/.venv/bin/python" -m pip install --upgrade pip
    if [[ "${PROJECT_TYPE}" == "pyproject" ]]; then
        "${PROJECT_DIR}/.venv/bin/python" -m pip install -e "${PROJECT_DIR}"
    else
        "${PROJECT_DIR}/.venv/bin/python" -m pip install -r "${PROJECT_DIR}/requirements.txt"
    fi
fi

echo "==> Step 4: Staging and committing initial project files..."
git add .
git commit -m "feat: initial professional repository structure"

echo "==> Step 5: Creating ${VISIBILITY} GitHub repository and pushing code..."
gh repo create "${REPO_NAME}" "--${VISIBILITY}" --source=. --remote=origin --push

echo "==> Step 6: Opening project workspace in Cloud Shell editor..."
if command -v cloudshell >/dev/null 2>&1; then
    cloudshell workspace "${PROJECT_DIR}"
    cloudshell edit "${PROJECT_DIR}/src/main.py"
fi

echo "=================================================================="
echo "Project '${REPO_NAME}' initialized successfully and pushed to GitHub."
echo "Workspace location: ${PROJECT_DIR}"
echo "=================================================================="
