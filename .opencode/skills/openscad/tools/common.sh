#!/bin/bash
# Common utilities for OpenSCAD tools

# Find OpenSCAD executable — nightly only, fail loud if missing.
find_openscad() {
    if command -v openscad-nightly &> /dev/null; then
        echo "openscad-nightly"
        return 0
    fi
    return 1
}

# Check if OpenSCAD nightly is available
check_openscad() {
    OPENSCAD=$(find_openscad) || {
        echo "Error: openscad-nightly not found!"
        echo ""
        echo "Install OpenSCAD nightly only (no 2021.01 fallback):"
        echo "  sudo apt-get install -y openscad-nightly"
        echo "  (OBS home:t-paul xUbuntu_24.04, arm64 build available)"
        echo "  https://openscad.org/downloads.html (nightly builds)"
        exit 1
    }
    export OPENSCAD
}

# Get version info
openscad_version() {
    check_openscad
    $OPENSCAD --version 2>&1
}
