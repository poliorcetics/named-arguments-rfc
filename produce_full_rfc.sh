RFC_FILE="0000-named-arguments-rfc.md"

function write_file() {
    cat $1 > ${RFC_FILE}
    echo "" >> ${RFC_FILE}
}

write_file 00-intro.md
write_file 01-goals.md
write_file 02-motivation.md
write_file 03-past-rust-only-discussions.md
write_file 04-other-languages.md
write_file 05-proposed-solution.md
write_file 06-alternatives.md
