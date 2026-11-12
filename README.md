# Add in local manifest

```xml
 <remote  name="frnAlt"
           fetch="https://github.com/frnAlt"
           revision="main" />

<project path="packages/apps/Screen_Recoder" name="android_packages_apps_Screen_Recoder" remote="frnAlt" revision="main" />
```

# Add following in device.mk

```makefile
# MIUI Screen Recorder
$(call inherit-product, packages/apps/Screen_Recoder/config.mk)
```

Source of APK: https://pixeldrain.com/u/eVHCk9kQ (`com.miui.screenrecorder` 4.16.2.9.1 version)

https://www.virustotal.com/gui/file/f8ebcce15bcfcbe2be8f733650975bf843a0bab7f717b20b0398ff3cdb585bd8

---

## AOSP Prebuilt Integration & Logic

This package integrates the Screen Recorder prebuilt application for AOSP and custom ROM build trees via Soong (`Android.bp`):

```blueprint
android_app_import {
	name: "MiuiScreenRecorder",
	owner: "xiaomi",
	apk: "prebuilt/screen_recoder.apk",
	presigned: true,
	dex_preopt: {
		enabled: false,
	},
	preprocessed: true,
	privileged: false,
	product_specific: true,
	skip_preprocessed_apk_checks: true,
}
```

### Prebuilt Flags Explanation
- **`presigned: true`**: Retains the existing official signature. AOSP will not strip the signature or re-sign the APK with default build keys.
- **`preprocessed: true`**: Required for prebuilt, presigned APKs targeting SDK 30+ (this APK targets SDK 36) signed with APK Signature Scheme v2/v3 to prevent Soong from corrupting the archive.
- **`skip_preprocessed_apk_checks: true`**: Prevents Soong build failures when an APK contains compressed or specific JNI native libraries (`libmievent.so`), ensuring clean ROM compilation.
- **`dex_preopt: { enabled: false }`**: Bypasses ahead-of-time dex optimization during the build process to avoid runtime packaging conflicts.

---

## Unpack and Repack Guide

If you need to unpack, inspect, or repack the recorder APK:

### 1. Unpacking the APK
To unpack and inspect the raw contents and libraries:
```bash
./scripts/unpack_repack.sh unpack
```
Or manually:
```bash
unzip prebuilt/screen_recoder.apk -d work_unpacked
```

To decompile resources and smali bytecode using `apktool`:
```bash
apktool d prebuilt/screen_recoder.apk -o screen_recorder_src
```

### 2. Repacking & Page-Aligning
When repacking the APK, native libraries (`lib/**/*.so`) must be stored uncompressed (`-0`) and 4-byte / 16KB page-aligned for Android 14+:
```bash
./scripts/unpack_repack.sh repack
```

Or manually:
```bash
cd work_unpacked
# 1. Archive native libraries uncompressed
zip -q -r -0 ../repacked.apk lib/
# 2. Add remaining assets and code
zip -q -r -u ../repacked.apk . -x "lib/*" "META-INF/*"
cd ..
# 3. Align 4-byte / page boundaries
zipalign -p -f 4 repacked.apk prebuilt/screen_recoder.apk
# 4. Sign with your ROM/test keys (if modified)
apksigner sign --key testkey.pk8 --cert testkey.x509.pem prebuilt/screen_recoder.apk
```
