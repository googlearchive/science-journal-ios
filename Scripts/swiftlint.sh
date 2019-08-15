#!/usr/bin/env bash

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
config_path="${script_path}/../.swiftlint.yml"
source_path="${script_path}/../ScienceJournal"
swiftlint_path="${script_path}/../Pods/SwiftLint/swiftlint"

# Create a `.swiftlint.options.local` file in the same directory as
# `.swiftlint.yml` to override options. Leave the file empty to suppress
# default options.
options_path="${script_path}/../.swiftlint.options.local"
options=""
strict_option="--strict"

# Check supported options if the `.swiftlint.options.local` file exists.
if [[ -f "$options_path" ]]; then
  if grep -- "$strict_option" "$options_path" > /dev/null 2>&1; then
    options="$options $strict_option"
  fi
# Otherwise set the default options.
else
  options="$strict_option"
fi

lint_command="${swiftlint_path} lint ${options} --config ${config_path} ${source_path}"

$lint_command
