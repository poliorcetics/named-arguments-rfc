#!/usr/bin/env sh

# Simple script to mash the different markdown files together and
# produce the single document necessary for the RFC PR.

set -Eeuo pipefail

RFC_FILE="0000-named-arguments-rfc.md"

# Clearing the file's content.
echo "Clearing $RFC_FILE"
echo "" > ${RFC_FILE}

function write_file() {
    cat $1 >> ${RFC_FILE}
    echo "" >> ${RFC_FILE}
}

echo "Writing $RFC_FILE"
write_file 00-intro-summary.md
write_file 01-motivation.md
write_file 02-guide-level-explanation.md
write_file 03-reference-level-explanation.md
write_file 04-drawbacks.md
write_file 05-rationale-and-alternatives.md
write_file 06-prior-art.md
write_file 07-unresolved-questions.md
write_file 08-future-possibilities.md
echo "Done"
