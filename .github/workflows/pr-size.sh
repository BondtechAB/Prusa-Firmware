#!/bin/sh
MESSAGE=$1
BASE_DIR=$2
PR_DIR=$3
shift 3

# this assumes we're running from the repository root
AVR_SIZE=$(echo .dependencies/avr-gcc-*/bin/avr-size)
test -x "$AVR_SIZE" || exit 2

avr_size()
{
    "$AVR_SIZE" --mcu=atmega2560 -C "$@"
}

avr_flash()
{
    avr_size "$@" | sed -ne 's/^Program: *\([0-9]\+\).*/\1/p'
}

avr_ram()
{
    avr_size "$@" | sed -ne 's/^Data: *\([0-9]\+\).*/\1/p'
}

cat <<EOF > "$MESSAGE"
| Target | ΔFlash (bytes) | ΔSRAM (bytes) |
| ------ | -------------- | ------------- |
EOF
for TARGET in $@
do
    # strip the multilang prefix
    variant=${TARGET%_MULTILANG}

    base_bin=$(echo ${BASE_DIR}/build_gen/$variant/${variant}_lang_base)
    base_flash=$(avr_flash "$base_bin")
    base_ram=$(avr_ram "$base_bin")

    pr_bin=$(echo ${PR_DIR}/build_gen/$variant/${variant}_lang_base)
    pr_flash=$(avr_flash "$pr_bin")
    pr_ram=$(avr_ram "$pr_bin")

    flash_d=$(($pr_flash - $base_flash))
    ram_d=$(($pr_ram - $base_ram))

    echo "| \`$TARGET\` | $flash_d | $ram_d |" >> "$MESSAGE"
done
