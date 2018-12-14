#
# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Generates classes from proto files. This script should not be run
# directly, it runs automatically as part of `pod install` instead.

#!/bin/bash

OUTPUT_DIR="../"
PROCESSING_DIR="third_party/sciencejournal/ios/Protos"

# Make sure the output and processing directories exist or create them.
mkdir -p "$OUTPUT_DIR"
mkdir -p "$PROCESSING_DIR"

# Move the protos to the processing directory to work around import requirements.
for file in *; do
  if test -f "$file" && [ "$file" != $(basename $0) ] && [ "$file" != "ScienceJournalPortableFilter.pbascii" ]; then
    mv "$file" "$PROCESSING_DIR/$file"
  fi
done

# Process the moved files.
for file in "$PROCESSING_DIR"/*; do
  protoc "$file" --objc_out="$OUTPUT_DIR"
done

# Move the protos back to their normal directory.
for file in "$PROCESSING_DIR"/*; do
  mv "$file" "$(pwd)/${file##*/}"
done

# Clean the imports on the generated files to work in the open source project's hierarchy.
for generatedFile in "$(pwd)/../third_party/sciencejournal/ios/Protos"/*; do
  sed -i "" "s/#import \"third_party\/sciencejournal\/ios\/Protos\//#import \"/g" $generatedFile
done
