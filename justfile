# Default, generate full output and format
default:
    @just generate
    @just format

# Generate the full RFC file
generate:
    ./produce_full_rfc.sh

# Format files in places
format:
    prettier -lw *.md
