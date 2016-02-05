#!/bin/sh


vultr_endpoint="https://api.vultr.com/v1"


dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"


case "$1" in

    build-initrd)
        echo "Building initrd..."
        (
            cd "$dir"
            rm -rf build
            mkdir build
            cd preseed-initrd
            find . -depth | cpio --quiet -H newc -o > ../build/preseed-initrd.cpio
            cd ../build
            gzip -9 -n > preseed-initrd.cpio.gz < preseed-initrd.cpio
            base64 > preseed-initrd.cpio.base64 < preseed-initrd.cpio
            base64 > preseed-initrd.cpio.gz.base64 < preseed-initrd.cpio.gz
        )
    ;;

    vultr-create)
        if [ -z "$2" ]; then
            echo "[error] You MUST specify a label/hostname."
            exit 1
        fi
        echo "Sending Vultr API command: Create Server..."
        (
            cd "$dir"
            vultr_command=server/create
            printf "${vultr_endpoint}/${vultr_command}?api_key=" | \
                cat - secrets/VULTR_API_KEY | \
                sed -e 's/^/url = "/' -e 's/$/"/' | \
                curl --config - --silent \
                    --data-urlencode "userdata@build/preseed-initrd.cpio.base64" \
                    -d "DCID=1" -d "VPSPLANID=29" \
                    -d "OSID=159" -d "SCRIPTID=14374" \
                    -d "enable_ipv6=yes" -d "enable_private_network=yes" \
                    -d "label=${2}"
        )
        if [ "$?" -ne 0 ]; then
            echo "[error] Vultr API call failed."
            exit 1
        fi
    ;;

    *)
        echo "[error] Invalid command \"$1\"."
        exit 1
    ;;

esac

echo "[success] ;)"
exit 0
