#!/usr/bin/env bash

# agent-teams-playbook Installation Script
# Version: V4.7
# Description: Installs the agent-teams-playbook Skill for Claude Code, Codex, OpenClaw, or Cursor
# Note: "swarm/蜂群" is generic; Claude Code's official concept is "Agent Teams"

set -e

VERSION="V4.7"
SKILL_NAME="agent-teams-playbook"
GITHUB_REPO="KimYx0207/agent-teams-playbook"
GITHUB_BRANCH="main"
INSTALL_TARGET="claude"
INSTALL_SOURCE="local"

CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-${HOME}/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-${HOME}/.codex/skills}"
OPENCLAW_SKILLS_DIR="${OPENCLAW_SKILLS_DIR:-${HOME}/.agents/skills}"
CURSOR_SKILLS_DIR="${CURSOR_SKILLS_DIR:-${HOME}/.cursor/skills}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

show_help() {
    cat << EOF
agent-teams-playbook Installation Script ${VERSION}

USAGE:
    ./install.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    -t, --target TARGET     Install target: claude, codex, openclaw, cursor, all
    --from-github           Download SKILL.md and README.md from GitHub main.
                            Default: copy from the local checkout.

DESCRIPTION:
    Installs the agent-teams-playbook Skill by:
    1. Detecting your operating system
    2. Creating the installation directory
    3. Copying SKILL.md and README.md from the local checkout
       or downloading them from GitHub with --from-github
    4. Verifying the installation
    5. Optionally enabling Claude Code fork mode

EXAMPLES:
    ./install.sh                         # Install for Claude Code
    ./install.sh --target codex          # Install for Codex
    ./install.sh --target openclaw       # Install for OpenClaw
    ./install.sh --target cursor         # Install for Cursor
    ./install.sh --target all            # Install for all supported targets
    ./install.sh --target all --from-github
    CODEX_SKILLS_DIR=/path/to/skills ./install.sh --target codex

EOF
}

show_version() {
    echo "agent-teams-playbook Installation Script ${VERSION}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -t|--target)
            if [[ -z "${2:-}" ]]; then
                print_error "--target requires a value"
                exit 1
            fi
            INSTALL_TARGET="$2"
            shift
            ;;
        --target=*)
            INSTALL_TARGET="${1#*=}"
            ;;
        --from-github)
            INSTALL_SOURCE="github"
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

target_dir() {
    case "$1" in
        claude) echo "${CLAUDE_SKILLS_DIR}/${SKILL_NAME}" ;;
        codex) echo "${CODEX_SKILLS_DIR}/${SKILL_NAME}" ;;
        openclaw) echo "${OPENCLAW_SKILLS_DIR}/${SKILL_NAME}" ;;
        cursor) echo "${CURSOR_SKILLS_DIR}/${SKILL_NAME}" ;;
        *)
            print_error "Unsupported target: $1" >&2
            print_error "Supported targets: claude, codex, openclaw, cursor, all" >&2
            return 1
            ;;
    esac
}

# Feature 1: OS Detection
detect_os() {
    print_header "Step 1: Detecting Operating System"

    local os_type=""
    local os_name=""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="Linux"
        os_name=$(uname -s)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
        os_name="macOS $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        os_type="Windows (Git Bash/MSYS)"
        os_name="Windows"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        os_type="Windows (WSL)"
        os_name="WSL $(uname -r)"
    else
        os_type="Unknown"
        os_name="$OSTYPE"
    fi

    print_info "Detected OS: ${os_type}"
    print_info "System: ${os_name}"
    echo
}

# Feature 2: Directory Creation
create_directory() {
    local install_dir="$1"
    print_header "Step 2: Creating Installation Directory"

    print_info "Target directory: ${install_dir}"

    if [ -d "${install_dir}" ]; then
        print_warning "Directory already exists!"
        echo
        read -p "Do you want to overwrite the existing installation? (y/N): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation aborted by user"
            exit 1
        fi

        print_info "Removing existing directory..."
        rm -rf "${install_dir}"
    fi

    mkdir -p "${install_dir}"
    print_success "Directory created successfully"
    echo
}

# Feature 3: File Download
copy_local_files() {
    local install_dir="$1"
    print_header "Step 3: Copying Files from Local Checkout"

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_dir
    repo_dir="$(cd "${script_dir}/.." && pwd)"
    local files=("SKILL.md" "README.md")

    for file in "${files[@]}"; do
        local source="${repo_dir}/${file}"
        local output="${install_dir}/${file}"

        print_info "Copying ${file}..."

        if [ ! -f "${source}" ]; then
            print_error "Local source file not found: ${source}"
            exit 1
        fi

        cp "${source}" "${output}"
        print_success "${file} copied successfully"
    done

    echo
}

download_files() {
    local install_dir="$1"
    print_header "Step 3: Downloading Files from GitHub"

    local base_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"
    local files=("SKILL.md" "README.md")
    local download_cmd=""

    # Determine download command (curl with fallback to wget)
    if command -v curl &> /dev/null; then
        download_cmd="curl"
        print_info "Using curl for downloads"
    elif command -v wget &> /dev/null; then
        download_cmd="wget"
        print_info "Using wget for downloads"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    echo

    for file in "${files[@]}"; do
        local url="${base_url}/${file}"
        local output="${install_dir}/${file}"

        print_info "Downloading ${file}..."

        if [ "$download_cmd" = "curl" ]; then
            if curl -fsSL -o "${output}" "${url}"; then
                print_success "${file} downloaded successfully"
            else
                print_error "Failed to download ${file}"
                print_error "URL: ${url}"
                exit 1
            fi
        else
            if wget -q -O "${output}" "${url}"; then
                print_success "${file} downloaded successfully"
            else
                print_error "Failed to download ${file}"
                print_error "URL: ${url}"
                exit 1
            fi
        fi
    done

    echo
}

# Feature 4: Installation Verification
verify_installation() {
    local install_dir="$1"
    print_header "Step 4: Verifying Installation"

    local files=("SKILL.md" "README.md")
    local all_valid=true

    for file in "${files[@]}"; do
        local filepath="${install_dir}/${file}"

        if [ ! -f "${filepath}" ]; then
            print_error "${file} does not exist"
            all_valid=false
        elif [ ! -s "${filepath}" ]; then
            print_error "${file} is empty"
            all_valid=false
        else
            local filesize=$(wc -c < "${filepath}" | tr -d ' ')
            local filesize_kb=$((filesize / 1024))
            print_success "${file} verified (${filesize} bytes / ${filesize_kb} KB)"
        fi
    done

    echo

    if [ "$all_valid" = true ]; then
        print_success "All files verified successfully!"
        return 0
    else
        print_error "Installation verification failed"
        return 1
    fi
}

# Feature 5: Fork Mode Prompt
configure_fork_mode() {
    local install_dir="$1"
    local target="$2"

    if [ "${target}" != "claude" ]; then
        print_header "Step 5: Fork Mode Configuration"
        print_info "Fork mode is a Claude Code-specific frontmatter option; skipping for ${target}."
        echo
        return 0
    fi

    print_header "Step 5: Fork Mode Configuration"

    print_info "Fork mode runs the skill in an isolated context."
    print_info "This prevents context pollution but increases token usage."
    echo

    read -p "Do you want to enable fork mode? (y/N): " -n 1 -r
    echo
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local skill_file="${install_dir}/SKILL.md"

        # Check if context: fork already exists
        if grep -q "^context:" "${skill_file}"; then
            print_warning "Fork mode configuration already exists in SKILL.md"
            print_info "Updating existing configuration..."

            # Use sed to replace existing context line
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS sed requires empty string after -i
                sed -i '' 's/^context:.*$/context: fork/' "${skill_file}"
            else
                sed -i 's/^context:.*$/context: fork/' "${skill_file}"
            fi
        else
            # Add context: fork on line 2 (right after opening ---)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '1a\
context: fork
' "${skill_file}"
            else
                sed -i '1a context: fork' "${skill_file}"
            fi
        fi

        print_success "Fork mode enabled"
    else
        print_info "Fork mode disabled (default)"
    fi

    echo
}

# Main installation flow
main() {
    echo
    print_header "agent-teams-playbook Installation ${VERSION}"
    echo

    detect_os

    local targets=()
    case "${INSTALL_TARGET}" in
        all)
            targets=("claude" "codex" "openclaw" "cursor")
            ;;
        claude|codex|openclaw|cursor)
            targets=("${INSTALL_TARGET}")
            ;;
        *)
            print_error "Unsupported target: ${INSTALL_TARGET}"
            print_error "Supported targets: claude, codex, openclaw, cursor, all"
            exit 1
            ;;
    esac

    local installed_locations=()

    for target in "${targets[@]}"; do
        local install_dir
        install_dir=$(target_dir "${target}") || exit 1

        print_header "Installing for ${target}"
        create_directory "${install_dir}"

        if [ "${INSTALL_SOURCE}" = "github" ]; then
            download_files "${install_dir}"
        else
            copy_local_files "${install_dir}"
        fi

        if verify_installation "${install_dir}"; then
            configure_fork_mode "${install_dir}" "${target}"
            installed_locations+=("${target}: ${install_dir}")
        else
            print_error "Installation failed during verification for ${target}"
            exit 1
        fi
    done

    print_header "Installation Complete!"
    print_success "agent-teams-playbook skill installed successfully"
    echo
    print_info "Installation locations:"
    for location in "${installed_locations[@]}"; do
        print_info "  - ${location}"
    done
    echo
}

# Run main installation
main
