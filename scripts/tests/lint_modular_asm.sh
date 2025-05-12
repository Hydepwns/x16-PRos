#!/bin/bash
# lint_modular_asm.sh - Advanced modular assembly linter and auto-fixer

set -e

echo "=== Modular Assembly Linter ==="

# 1. Aggregator modules should not be built as object files
# (You may need to update AGGREGATORS if you add more aggregator modules)
AGGREGATORS=("src/fs/dir.asm" "src/fs/fat.asm")
echo "Checking for aggregator modules in build targets..."
for agg in "${AGGREGATORS[@]}"; do
    # Only flag if aggregator appears in an uncommented build command, and exclude this linter script
    offending=$(grep -E '^[[:space:]]*(nasm|ld|gcc|as|objcopy|objdump)' scripts/build/* \
        | grep -v "lint_modular_asm.sh" \
        | grep -vE '^[[:space:]]*#' \
        | grep -vE "#.*$agg" \
        | grep "$agg" || true)
    if [ -n "$offending" ]; then
        echo "ERROR: Aggregator $agg should not be a build target!"
        echo "Offending line(s):"
        echo "$offending"
        exit 1
    fi
done

# 2. Only one implementation of each global error function
ERROR_FUNCS=(set_error get_error print_error)
echo "Checking for multiple global error function implementations..."
for fn in "${ERROR_FUNCS[@]}"; do
    count=$(grep -r "global $fn" src/ | wc -l)
    if [ "$count" -gt 1 ]; then
        echo "ERROR: Multiple implementations of $fn found!"
        grep -r "global $fn" src/
        exit 1
    fi
done

# 3. Remove direct includes of errors.asm except in errors.asm itself
echo "Auto-fixing direct includes of errors.asm..."
find src/ -type f -name "*.asm" ! -name "errors.asm" -exec \
    sed -i.bak '/%include "src\/fs\/errors.asm"/d' {} \;

# 4. Check for missing externs (warn only)
echo "Checking for missing extern declarations for error functions..."
for fn in "${ERROR_FUNCS[@]}"; do
    grep -r "$fn" src/ | grep -v "extern $fn" | grep -v "global $fn" | \
    grep -v "src/fs/errors.asm" | grep -v '\.inc' && \
    echo "WARNING: $fn used without extern or global declaration."
done

# 5. Remove global from helper functions (auto-fix, except for error functions)
echo "Auto-fixing global directives for helper functions..."
find src/ -type f -name "*.asm" ! -name "errors.asm" -print0 | \
    while IFS= read -r -d '' f; do \
        awk '/^global[ \t]+(set_error|get_error|print_error)/ {print; next} /^global[ \t]+/ {next} {print}' \
            "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done

# 6. Clean up backup files
find src/ -type f -name "*.bak" -delete

echo "Linting and auto-fix complete."

exit 0
