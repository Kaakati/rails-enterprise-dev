#!/bin/bash

# ReAcTree iOS/tvOS Development Plugin - Installation Script
# Version: 2.0.0
# Author: Mohamad Kaakati

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Plugin information
PLUGIN_NAME="reactree-ios-dev"
PLUGIN_VERSION="2.0.0"
PLUGIN_DISPLAY_NAME="ReAcTree iOS/tvOS Development"

echo -e "${BLUE}"
cat <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     ReAcTree iOS/tvOS Development Plugin Installer       ║
║                    Version 2.0.0                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to print success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error message
error() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Function to print warning message
warning() {
    echo -e "${YELLOW}⚠️  Warning: $1${NC}"
}

# Function to print info message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Step 1: Detect installation directory
echo ""
info "Step 1: Detecting installation directory..."

if [ -d "*.xcodeproj" ] || [ -d "*.xcworkspace" ]; then
    # We're in an Xcode project directory
    INSTALL_DIR="$(pwd)/.claude/plugins/$PLUGIN_NAME"
    info "Installing to Xcode project at: $(pwd)"
elif [ -d ".claude" ]; then
    # We're in a directory with .claude folder
    INSTALL_DIR="$(pwd)/.claude/plugins/$PLUGIN_NAME"
    info "Installing to current directory: $(pwd)"
else
    # Ask user for installation directory
    echo ""
    echo "Where would you like to install the plugin?"
    echo "1) Current directory: $(pwd)"
    echo "2) Specify custom path"
    read -p "Enter choice (1 or 2): " choice

    if [ "$choice" = "1" ]; then
        INSTALL_DIR="$(pwd)/.claude/plugins/$PLUGIN_NAME"
    elif [ "$choice" = "2" ]; then
        read -p "Enter full path to iOS/tvOS project: " custom_path
        INSTALL_DIR="$custom_path/.claude/plugins/$PLUGIN_NAME"
    else
        error "Invalid choice"
    fi
fi

# Step 2: Create directory structure
echo ""
info "Step 2: Creating directory structure..."

mkdir -p "$(dirname "$INSTALL_DIR")"
success "Created plugins directory"

# Step 3: Get plugin source directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_SOURCE="$SCRIPT_DIR"

info "Plugin source: $PLUGIN_SOURCE"
info "Installation target: $INSTALL_DIR"

# Step 4: Copy plugin files
echo ""
info "Step 3: Copying plugin files..."

# Check if source exists
if [ ! -d "$PLUGIN_SOURCE/.claude-plugin" ]; then
    error "Plugin source not found at $PLUGIN_SOURCE"
fi

# Remove existing installation if present
if [ -d "$INSTALL_DIR" ]; then
    warning "Existing installation found. Removing..."
    rm -rf "$INSTALL_DIR"
fi

# Copy plugin
cp -r "$PLUGIN_SOURCE" "$INSTALL_DIR"
success "Copied plugin to $INSTALL_DIR"

# Step 5: Verify installation
echo ""
info "Step 4: Verifying installation..."

# Check for critical files
if [ ! -f "$INSTALL_DIR/.claude-plugin/plugin.json" ]; then
    error "plugin.json not found. Installation may be corrupted."
fi

AGENT_COUNT=$(find "$INSTALL_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
SKILL_COUNT=$(find "$INSTALL_DIR/skills" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
RULE_COUNT=$(find "$INSTALL_DIR/rules" -name "*.md" | wc -l | tr -d ' ')
COMMAND_COUNT=$(find "$INSTALL_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
EXAMPLE_COUNT=$(find "$INSTALL_DIR/examples" -name "*.md" | wc -l | tr -d ' ')

success "Verified $AGENT_COUNT agents"
success "Verified $SKILL_COUNT skills"
success "Verified $RULE_COUNT rules"
success "Verified $COMMAND_COUNT commands"
success "Verified $EXAMPLE_COUNT examples"

# Step 6: Check dependencies
echo ""
info "Step 5: Checking dependencies..."

# Check for Xcode
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -1)
    success "Xcode found: $XCODE_VERSION"
else
    warning "Xcode not found. Please install Xcode 14.0 or later."
fi

# Check for Swift
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | grep -o 'Swift version [0-9.]*' | grep -o '[0-9.]*')
    success "Swift found: $SWIFT_VERSION"

    # Validate Swift version
    REQUIRED_VERSION="5.7"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$SWIFT_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        warning "Swift $REQUIRED_VERSION or higher recommended (found $SWIFT_VERSION)"
    fi
else
    warning "Swift compiler not found"
fi

# Check for SwiftLint
if command -v swiftlint &> /dev/null; then
    SWIFTLINT_VERSION=$(swiftlint version)
    success "SwiftLint found: $SWIFTLINT_VERSION"
else
    warning "SwiftLint not found. Install with: brew install swiftlint"
    echo "   SwiftLint is required for quality gates"
fi

# Check for SwiftGen (optional)
if command -v swiftgen &> /dev/null; then
    SWIFTGEN_VERSION=$(swiftgen --version)
    success "SwiftGen found: $SWIFTGEN_VERSION"
else
    info "SwiftGen not found (optional). Install with: brew install swiftgen"
fi

# Step 7: Display next steps
echo ""
echo -e "${GREEN}"
cat <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          ✨ Installation Complete! ✨                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}📦 What was installed:${NC}"
echo "   • $AGENT_COUNT specialized agents"
echo "   • $SKILL_COUNT comprehensive skills"
echo "   • $RULE_COUNT architectural rules"
echo "   • $COMMAND_COUNT workflow commands"
echo "   • $EXAMPLE_COUNT implementation examples"
echo ""

echo -e "${BLUE}📁 Installation location:${NC}"
echo "   $INSTALL_DIR"
echo ""

echo -e "${BLUE}🚀 Next Steps:${NC}"
echo ""
echo "1. Navigate to your iOS/tvOS project:"
PROJECT_DIR=$(dirname "$(dirname "$INSTALL_DIR")")
echo "   ${GREEN}cd \"$PROJECT_DIR\"${NC}"
echo ""

echo "2. Initialize the plugin in your project:"
echo "   ${GREEN}/ios-init${NC}"
echo ""

echo "3. (Optional) Install dependencies if not already installed:"
echo "   ${GREEN}brew install swiftlint${NC}"
echo "   ${GREEN}brew install swiftgen${NC}  # Optional"
echo ""

echo "4. Start building features:"
echo "   ${GREEN}/ios-dev add user authentication with JWT tokens${NC}"
echo ""

echo -e "${BLUE}📚 Available Commands:${NC}"
echo "   • ${GREEN}/ios-init${NC}      - Initialize plugin in your project"
echo "   • ${GREEN}/ios-dev${NC}       - Main development workflow"
echo "   • ${GREEN}/ios-feature${NC}   - Feature-driven development"
echo "   • ${GREEN}/ios-debug${NC}     - Debugging workflow"
echo "   • ${GREEN}/ios-refactor${NC}  - Refactoring workflow"
echo ""

echo -e "${BLUE}📖 Documentation:${NC}"
echo "   • README:   $INSTALL_DIR/README.md"
echo "   • Examples: $INSTALL_DIR/examples/"
echo "   • Custom:   $INSTALL_DIR/CUSTOMIZATION.md"
echo ""

echo -e "${BLUE}🔗 Resources:${NC}"
echo "   • Repository: https://github.com/kaakati/ios-enterprise-dev"
echo "   • Issues:     https://github.com/kaakati/ios-enterprise-dev/issues"
echo "   • Changelog:  $INSTALL_DIR/CHANGELOG.md"
echo ""

echo -e "${GREEN}Thank you for installing $PLUGIN_DISPLAY_NAME v$PLUGIN_VERSION!${NC}"
echo ""

# Optional: Create desktop shortcut or bookmark
if [ "$(uname)" = "Darwin" ]; then
    echo -e "${BLUE}💡 Tip:${NC} Bookmark this location in Finder for quick access:"
    echo "   open \"$INSTALL_DIR\""
    echo ""
fi

# Success!
exit 0
