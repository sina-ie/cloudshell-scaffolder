# Cloud Shell Project Scaffolder (`setup_project.sh`)

[!License: MIT](LICENSE)

A robust, zero-friction automation script for scaffolding production-ready Python projects in **Google Cloud Shell** and local Linux environments.

It provisions project architecture, local Git repository, GitHub remotes (`--public` or `--private`), VS Code debugging configurations, virtual environments, unit tests, and GitHub Actions CI pipelines in a single command.

## Features

- **Automated GitHub Repository Setup**: Creates remote repositories directly from the terminal via GitHub CLI (`gh`).
- **Multiple Dependency Standards**:
  - Standard `pip` workflow using `requirements.txt`.
  - Modern PEP 621 packaging using `pyproject.toml` (Hatchling backend).
- **High-Performance Provisioning**: Optional `uv` support for sub-second virtual environment and dependency setups.
- **VS Code & Cloud Shell Editor Ready**:
  - Pre-configured `.vscode/launch.json` for F5 debugging.
  - Integrated tasks (`tasks.json`) and pytest test discovery (`settings.json`).
- **Automated CI/CD**: Pre-configured GitHub Actions workflow testing on push and pull requests.

## Prerequisites

- **GitHub CLI (`gh`)**: Authenticated (`gh auth status` or `gh auth login`).
- **Python**: Version 3.11+.
- **(Optional) uv**: For high-speed dependency installations.

## Usage

Clone and execute directly:
```bash
git clone https://github.com/sina-ie/cloudshell-scaffolder.git
cd cloudshell-scaffolder
chmod +x setup_project.sh
```

Execute with standard arguments:
```bash
./setup_project.sh [PROJECT_NAME] [OPTIONS]
```

### Options & Flags

| Option | Description | Default |
| :--- | :--- | :--- |
| `-n, --name <NAME>` | Name of the project directory and remote GitHub repository | `my-app` |
| `-t, --type <TYPE>` | Dependency layout: `pip` or `pyproject` | `pip` |
| `-u, --uv` | Use `uv` instead of standard `venv`/`pip` | `false` |
| `--public` | Create a public GitHub repository | Off (`--private`) |
| `--private` | Create a private GitHub repository | Enabled |
| `-h, --help` | Display usage instructions | — |

### Examples

**1. Basic project with pip:**
```bash
./setup_project.sh my-service
```

**2. Modern public project using pyproject.toml and uv:**
```bash
./setup_project.sh --name fast-service --type pyproject --uv --public
```

## License

This project is licensed under the MIT License.
