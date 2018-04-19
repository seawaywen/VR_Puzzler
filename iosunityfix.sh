#!/bin/sh

# run this script from the root folder of your xcode project.
# for use in:
#   unity 5.6.0f3+,
#   gvr unity sdk v1.70.0+,

# relative path for the gvr unity fat lib.
LIB_FOLDER="Pods/GVRSDK/Libraries"
LIB_NAME="libGVRSDK"
LIB_PATH="${LIB_FOLDER}/${LIB_NAME}.a"

# fetch the audio symbols.
AUDIO_SYMBOLS=$(nm -Aj -arch all $LIB_PATH | grep vraudio \
  | sed -E 's/.*:(.*\.o):.*/\1/g' | sort -u)

# create a temp directory to populate the intermediate artifacts.
TMP_LIB_FOLDER="/tmp/iosunityfix"
rm -rf $TMP_LIB_FOLDER
mkdir -p $TMP_LIB_FOLDER

# iterate through the architectures of the fat lib.
for ARCH in i386 x86_64 armv7 arm64
do
  TMP_LIB_PATH="${TMP_LIB_FOLDER}/${LIB_NAME}_${ARCH}.a"
  lipo $LIB_PATH -thin $ARCH -output $TMP_LIB_PATH
  chmod +w $TMP_LIB_PATH
  # extract audio symbols from the thin lib.
  echo $AUDIO_SYMBOLS | xargs ar -d $TMP_LIB_PATH &> /dev/null
  ar -s $TMP_LIB_PATH &> /dev/null
done

# replace the universal (fat) lib.
chmod +w $LIB_PATH
lipo ${TMP_LIB_FOLDER}/* -create -output $LIB_PATH &> /dev/null

# remove intermediate artifacts.
rm -rf $TMP_LIB_FOLDER

# comment-out the audio header references from the xcode project.
XCODE_PROJ_PATH="Pods/Pods.xcodeproj/project.pbxproj"
chmod +w $XCODE_PROJ_PATH
sed -i -E 's/\(.*GVRAudioEngine.*\)/\/\/ \1/g' $XCODE_PROJ_PATH
