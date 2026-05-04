name: test
on: [push, pull_request]
jobs:
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - run: .\scripts\install.ps1 -All
      - run: .\scripts\build.ps1 -All
      - run: .\scripts\test.ps1 -All
  linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x scripts/*.sh
      - run: ./scripts/install.sh --all
      - run: ./scripts/build.sh --all
      - run: ./scripts/test.sh --all
