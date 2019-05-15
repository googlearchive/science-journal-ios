#!/usr/bin/env bash

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
config_path="${script_path}/../.swiftlint.yml"
source_path="${script_path}/../ScienceJournal"
swiftlint_path="${script_path}/../Pods/SwiftLint/swiftlint"
lint_command="${swiftlint_path} lint --strict --config ${config_path} ${source_path}"

lint_result="$($lint_command)"

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
