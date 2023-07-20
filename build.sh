#!/bin/bash
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

display_usage() {
    echo "Usage: "
    echo ""
    echo "build.sh [--with-tests] [--standalone] [--clean-install]"
    echo ""
    echo "Options:"
    echo "--with-tests - build with tests"
    echo "--standalone - standalone version"
    echo "--clean-install - makes a clean installation, removes install directory before deploying"
}

if [ ! -d "$SCRIPTPATH/src/ros2cs" ]; then
    echo "Pull repositories with 'pull_repositories.sh' first."
    exit 1
fi

# OPTIONS=""
STANDALONE=0
TESTS=0
CLEAN_INSTALL=0

ANDROID_NDK=""

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    # -t|--with-tests)
    #   OPTIONS="$OPTIONS --with-tests"
    #   TESTS=1
    #   shift # past argument
    #   ;;
    # -s|--standalone)
    #   if ! hash patchelf 2>/dev/null ; then
    #     echo "Patchelf missing. Standalone build requires patchelf. Install it via apt 'sudo apt install patchelf'."
    #     exit 1
    #   fi
    #   OPTIONS="$OPTIONS --standalone"
    #   STANDALONE=1
    #   shift # past argument
    #   ;;
    -c|--clean-install)
      CLEAN_INSTALL=1
      shift # past argument
      ;;
    -p|--ndk-path)
      ANDROID_NDK="$2"
      shift # past argument
      shift # past argument
      ;;
    -h|--help)
      display_usage
      exit 0
      shift # past argument
      ;;
    *)    # unknown option
      shift # past argument
      ;;
  esac
done

if [ $CLEAN_INSTALL == 1 ]; then
    echo "Cleaning install directory..."
    rm -rf $SCRIPTPATH/install/*
fi

if [ $STANDALONE == 1 ]; then
  python3 $SCRIPTPATH/src/scripts/metadata_generator.py --standalone
else
  python3 $SCRIPTPATH/src/scripts/metadata_generator.py
fi

if $SCRIPTPATH/src/ros2cs/build_android.sh -p ${ANDROID_NDK}; then
    mkdir -p $SCRIPTPATH/install/asset && cp -R $SCRIPTPATH/src/Ros2ForUnity $SCRIPTPATH/install/asset/
    $SCRIPTPATH/deploy_unity_plugins.sh $SCRIPTPATH/install/asset/Ros2ForUnity/Plugins/
    cp $SCRIPTPATH/src/Ros2ForUnity/metadata_ros2cs.xml $SCRIPTPATH/install/asset/Ros2ForUnity/Plugins/Android/metadata_ros2cs.xml
    cp $SCRIPTPATH/src/Ros2ForUnity/metadata_ros2cs.xml $SCRIPTPATH/install/asset/Ros2ForUnity/Plugins/metadata_ros2cs.xml

    mkdir -p $SCRIPTPATH/install/asset/Ros2ForUnity/Resources/
    cp $SCRIPTPATH/src/Ros2ForUnity/metadata_ros2cs.xml $SCRIPTPATH/install/asset/Ros2ForUnity/Resources/metadata_ros2cs.xml
    cp $SCRIPTPATH/src/Ros2ForUnity/metadata_ros2_for_unity.xml $SCRIPTPATH/install/asset/Ros2ForUnity/Resources/metadata_ros2_for_unity.xml
else
    echo "Ros2cs build failed!"
    exit 1
fi
