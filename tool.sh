#!/bin/sh


default_domain="littlebluetech.com"
vultr_endpoint="https://api.vultr.com/v1"

label="$2"

dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"


checkname () {
    if [ -z "${label}" ]; then
        echo "[error] You MUST specify a label/hostname."
        exit 1
    fi

    if echo "${label}" | grep -q -E -v '^[a-z0-9][-.a-z0-9]*[a-z0-9]$|^[a-z0-9]$' || \
       echo "${label}" | grep -q '[-.][-.]'
    then
        printf "[error] Invalid label/hostname: \"${label}\".\n"
        exit 1
    fi

    if echo "${label}" | grep -q '[.].*[.]' ; then
        printf "[warning] Label/hostname looks like an FQDN...\n"
        printf "          We will *NOT* append default domain.\n"
        fqdn="${label}"
    else
        fqdn="${label}.${default_domain}"
    fi

    printf "\nHost's FQDN: ${fqdn}\n"

    return 0
}


case "$1" in

    build)
        echo "Building initrd..."
        (
            cd "$dir"
            rm -rf build
            mkdir build
            cd preseed-initrd
            find . | cpio -o -H newc -R 0:0 --quiet > ../build/preseed-initrd.cpio
            cd ../build
            gzip -9 -n > preseed-initrd.cpio.gz < preseed-initrd.cpio
            base64 > preseed-initrd.cpio.base64 < preseed-initrd.cpio
            base64 > preseed-initrd.cpio.gz.base64 < preseed-initrd.cpio.gz
        )
    ;;

    deploy)
        checkname
        printf "\n\n"
        (
            vultr_command=server/create
            cd "$dir"
            printf "${vultr_endpoint}/${vultr_command}?api_key=" | \
                cat - secrets/VULTR_API_KEY | \
                sed -e 's/^/url = "/' -e 's/$/"/' | \
                curl --config - --silent \
                    --data-urlencode "userdata@build/preseed-initrd.cpio.base64" \
                    -d "DCID=1" -d "VPSPLANID=29" \
                    -d "OSID=159" -d "SCRIPTID=14374" \
                    -d "enable_ipv6=yes" -d "enable_private_network=yes" \
                    -d "label=${fqdn}"
        )
        if [ "$?" -ne 0 ]; then
            echo "[error] Vultr API call failed."
            exit 1
        fi
        printf "\n\n"
    ;;

    *)
        echo "[error] Invalid command \"$1\"."
        exit 1
    ;;

esac

echo "[success] ;)"
exit 0
