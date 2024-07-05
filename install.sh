#!/bin/sh

TEMP_DIR=./temp_swiftpm_settings_acknowledgements

mkdir $(TEMP_DIR)

# clone repository into temporary directory
# git clone "https://github.com/natesabrown/swiftpm-settings-acknowledgements" "$TEMP_DIR"
# git clone "/Users/nateabrown/Developer/spm-settings-acknowledgements" "$TEMP_DIR"
cp -r "/Users/nateabrown/Developer/spm-settings-acknowledgements" "$TEMP_DIR"

cd "$TEMP_DIR"

# install
make install

# copy to /usr/local/bin
# sudo cp -f .build/release/make-settings-from-spm /usr/local/bin

# remove the temporary directory
cd ..
# rm -rf "$TEMP_DIR"