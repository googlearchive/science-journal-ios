# Your first PR

## Prerequisites

Before you start working on Science Journal iOS, make sure you've read [CONTRIBUTING.md](https://github.com/google/science-journal-ios/blob/master/CONTRIBUTING.md).

## Finding things to work on

The core team usually tags issues that are ready to be worked on and easily accessible for new contributors with the [“you can do this” label][you can do this]. If you’ve never contributed to Science Journal iOS before, these are a great place to start!

If you want to work on something else, e.g. new functionality or fixing a bug, it would be helpful if you submit a new issue so we have a chance to discuss it first. We might have some pointers for you on how to get started, or how to best integrate it with existing solutions.

## Checking out the Science Journal iOS repo

- Click the “Fork” button in the upper right corner of the [main Science Journal iOS repo](https://github.com/google/science-journal-ios)
- Clone your fork:
  - `git clone git@github.com:<YOUR_GITHUB_USER>/science-journal-ios.git`
  - Learn more about how to manage your fork: [https://help.github.com/articles/working-with-forks/](https://help.github.com/articles/working-with-forks/)
- Install dependencies:
  - Run `pod install` in the project root
- Create a new branch to work on:
  - `git checkout -b <YOUR_BRANCH_NAME>`
  - A good name for a branch describes the thing you’ll be working on, e.g. `issue-132`, `fix-pitch-sensor-graph`, etc.
That’s it! Now you’re ready to work on Science Journal iOS

## Testing your changes

First, run unit tests: Select the `ScienceJournal` scheme, select a simulator target (e.g. iPhone X), then use Product > Test (or CMD+U) to run the test suite. Second: Test on device! We ask you test your change on both iPhone and iPad devices, if possible.

## Submitting a PR

When the coding is done and you’ve finished testing your changes, you're ready to submit a PR to the [Science Journal iOS main repo](https://github.com/google/science-journal-ios). Everything you need to know about submitting the PR itself is inside our [Pull Request Template][pr template]. Some best practices are:

- Use a descriptive title
- Link the issues related to your PR in the body

## After the review

Once a core member has reviewed your PR, you might need to make changes before it gets merged. To make it easier on us, please make sure to avoid using `git commit --amend` or force pushes to make corrections. By avoiding rewriting the commit history, you will allow each round of edits to become its own visible commit. This helps the people who need to review your code easily understand exactly what has changed since the last time they looked. Feel free to use whatever commit messages you like, as we will squash them anyway. When you are done addressing your review, also add a small comment like “Feedback addressed @<your_reviewer>”.

Before you make any changes after your code has been reviewed, you should always rebase the latest changes from the master branch.

After your contribution is merged, it’s not immediately available to all users. Your change will be shipped as part of the next release. If your change is time-sensitive, please let us know so we can schedule a release for your change.

<!-- Links -->
[you can do this]: https://github.com/google/science-journal-ios/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+label%3A%22complexity%3A+you+can+do+this%22+

