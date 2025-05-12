#!/bin/bash

# Shared color variables
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

# Default values (can be overridden by scripts)
DEFAULT_SECTORS=2880
DEFAULT_SECTOR_SIZE=512
VALID_SECTOR_SIZES=(256 512 1024 2048 4096)
VALID_DISK_FORMATS=("floppy360" "floppy720" "floppy144" "floppy288" "hdd")

# BUILD_MODE: 'release' or 'test'. Default is 'release'.
BUILD_MODE="${BUILD_MODE:-release}"

# Helper to set build mode (call early in your script)
set_build_mode() {
    if [ -n "$1" ]; then
        BUILD_MODE="$1"
    fi
}

# Usage:
#   set_build_mode test   # for test builds
#   set_build_mode release # for release builds
# Or set BUILD_MODE env var before running script

# Function to check if a command succeeded
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: Required command '$1' not found${NC}"
        echo -e "${YELLOW}Please install $1 and try again${NC}"
        exit 1
    fi
}

# Function to check if a file exists and is readable
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}Error: Required file '$1' not found${NC}"
        exit 1
    fi
    if [ ! -r "$1" ]; then
        echo -e "${RED}Error: Cannot read file '$1'${NC}"
        exit 1
    fi
}

# Function to check if a directory is writable
check_dir_writable() {
    if [ ! -w "$1" ]; then
        echo -e "${RED}Error: Cannot write to directory '$1'${NC}"
        exit 1
    fi
}

# Function to validate sector size
validate_sector_size() {
    local size=$1
    local valid=0
    for valid_size in "${VALID_SECTOR_SIZES[@]}"; do
        if [ "$size" -eq "$valid_size" ]; then
            valid=1
            break
        fi
    done
    if [ $valid -eq 0 ]; then
        echo -e "${RED}Error: Invalid sector size '$size'${NC}"
        echo -e "${YELLOW}Valid sector sizes are: ${VALID_SECTOR_SIZES[*]}${NC}"
        exit 1
    fi
}

# Function to validate disk format
validate_disk_format() {
    local format=$1
    local valid=0
    for valid_format in "${VALID_DISK_FORMATS[@]}"; do
        if [ "$format" = "$valid_format" ]; then
            valid=1
            break
        fi
    done
    if [ $valid -eq 0 ]; then
        echo -e "${RED}Error: Invalid disk format '$format'${NC}"
        echo -e "${YELLOW}Valid formats are: ${VALID_DISK_FORMATS[*]}${NC}"
        exit 1
    fi
}

# Function to get disk parameters from format (scripts may override)
get_disk_params() {
    local format=$1
    case "$format" in
        floppy360)
            DISK_SECTORS=720
            ;;
        floppy720)
            DISK_SECTORS=1440
            ;;
        floppy144)
            DISK_SECTORS=2880
            ;;
        floppy288)
            DISK_SECTORS=5760
            ;;
        hdd)
            DISK_SECTORS=20480
            ;;
    esac
}

# Usage: source this file in your build/test scripts
# Example: source "$(dirname "$0")/../utils/build_common.sh"

export DEFAULT_SECTORS
export DEFAULT_SECTOR_SIZE
export VALID_SECTOR_SIZES
export VALID_DISK_FORMATS 