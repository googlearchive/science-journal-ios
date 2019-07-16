#!/bin/bash

lint_command="swiftlint lint --strict"
lint_result="$($1$lint_command)"

# Turn all warnings into errors
lint_result="${lint_result/: warning:/: error:}"

# Echo out to Xcode if we have any errors
echo $lint_result

if [ ${#lint_result} -gt 0 ]
then
  # Since we had errors, make sure the engineer knows this is a lint error.
  echo "error: SwiftLint issues are preventing a successful build."
  exit -1
fi
