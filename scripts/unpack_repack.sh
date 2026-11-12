#!/usr/bin/env bash
# Helper script to unpack and repack the Screen Recorder prebuilt APK for AOSP

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK_PATH="${DIR}/prebuilt/screen_recoder.apk"
WORK_DIR="${DIR}/work_unpacked"
OUTPUT_APK="${DIR}/prebuilt/screen_recoder_repacked.apk"

action="${1:-help}"

case "$action" in
    unpack)
        echo "==> Unpacking ${APK_PATH} into ${WORK_DIR}..."
        rm -rf "${WORK_DIR}"
        mkdir -p "${WORK_DIR}"
        unzip -q "${APK_PATH}" -d "${WORK_DIR}"
        echo "==> Successfully unpacked to ${WORK_DIR}"
        ;;
    repack)
        if [ ! -d "${WORK_DIR}" ]; then
            echo "Error: ${WORK_DIR} does not exist. Run './scripts/unpack_repack.sh unpack' first."
            exit 1
        fi
        echo "==> Repacking from ${WORK_DIR}..."
        TEMP_ZIP="$(mktemp /tmp/apk_temp_XXXXXX.zip)"
        cd "${WORK_DIR}"
        # Ensure native libraries are stored uncompressed (-0)
        if [ -d "lib" ]; then
            zip -q -r -0 "${TEMP_ZIP}" lib/
        fi
        # Add remaining files, excluding existing signatures
        zip -q -r -u "${TEMP_ZIP}" . -x "lib/*" "META-INF/*"
        
        echo "==> Performing 4-byte / page alignment..."
        ALIGNED_APK="$(mktemp /tmp/apk_aligned_XXXXXX.apk)"
        zipalign -p -f 4 "${TEMP_ZIP}" "${ALIGNED_APK}"
        rm -f "${TEMP_ZIP}"

        echo "==> Output generated at: ${OUTPUT_APK}"
        mv "${ALIGNED_APK}" "${OUTPUT_APK}"
        echo "==> Notice: If the APK contents were modified, sign it with apksigner before installing:"
        echo "    apksigner sign --key <key.pk8> --cert <cert.pem> ${OUTPUT_APK}"
        ;;
    *)
        echo "Usage: $0 {unpack|repack}"
        exit 1
        ;;
esac
