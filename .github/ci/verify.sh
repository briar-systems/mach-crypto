# every test under src is collected by `mach test . --lib tests`, on every target.
# listing is target-independent work, so the primary leg carries it
if [[ "${MACH_CI_PRIMARY:-}" == true ]]; then
    tools/test-selection "$MACH_COMPILER"
fi
