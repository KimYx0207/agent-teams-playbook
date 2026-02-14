#!/usr/bin/env bash

# agent-teams-playbook Installation Script
# Version: V4.5
# Description: Installs the agent-teams-playbook Claude Code Skill
# Note: "swarm/蜂群" is generic; Claude Code's official concept is "Agent Teams"

set -e

VERSION="V4.5"
SKILL_NAME="agent-teams-playbook"
GITHUB_REPO="KimYx0207/agent-teams-playbook"
GITHUB_BRANCH="main"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"

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
    -h, --help      Show this help message
    -v, --version   Show version information

DESCRIPTION:
    Installs the agent-teams-playbook Claude Code Skill by:
    1. Detecting your operating system
    2. Creating the installation directory
    3. Downloading SKILL.md and README.md from GitHub
    4. Verifying the installation
    5. Optionally enabling fork mode

EXAMPLES:
    ./install.sh                # Run interactive installation
    ./install.sh --help         # Show this help message

EOF
}

show_version() {
    echo "agent-teams-playbook Installation Script ${VERSION}"
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
    print_header "Step 2: Creating Installation Directory"

    print_info "Target directory: ${INSTALL_DIR}"

    if [ -d "${INSTALL_DIR}" ]; then
        print_warning "Directory already exists!"
        echo
        read -p "Do you want to overwrite the existing installation? (y/N): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation aborted by user"
            exit 1
        fi

        print_info "Removing existing directory..."
        rm -rf "${INSTALL_DIR}"
    fi

    mkdir -p "${INSTALL_DIR}"
    print_success "Directory created successfully"
    echo
}

# Feature 3: File Download
download_files() {
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
        local output="${INSTALL_DIR}/${file}"

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
    print_header "Step 4: Verifying Installation"

    local files=("SKILL.md" "README.md")
    local all_valid=true

    for file in "${files[@]}"; do
        local filepath="${INSTALL_DIR}/${file}"

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
    print_header "Step 5: Fork Mode Configuration"

    print_info "Fork mode runs the skill in an isolated context."
    print_info "This prevents context pollution but increases token usage."
    echo

    read -p "Do you want to enable fork mode? (y/N): " -n 1 -r
    echo
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local skill_file="${INSTALL_DIR}/SKILL.md"

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
    create_directory
    download_files

    if verify_installation; then
        configure_fork_mode

        print_header "Installation Complete!"
        print_success "agent-teams-playbook skill installed successfully"
        echo
        print_info "Installation location: ${INSTALL_DIR}"
        print_info "You can now use the skill in Claude Code"
        echo
        print_info "To verify, check:"
        print_info "  - ${INSTALL_DIR}/SKILL.md"
        print_info "  - ${INSTALL_DIR}/README.md"
        echo
    else
        print_error "Installation failed during verification"
        exit 1
    fi
}

# Run main installation
main
