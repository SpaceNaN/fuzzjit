
# FuzzJIT: Oracle-Enhanced Fuzzing for JavaScript Engine JIT Compiler

FuzzJIT is a fuzzing tool for JavaScript engines JIT compiler, built on top of Fuzzilli.

The paper is accepted by USENIX Security 2023.

```
@inproceedings{fuzzjit,
  title        = {FuzzJIT: Oracle-Enhanced Fuzzing for JavaScript Engine JIT Compiler},
  author       = {Junjie Wang , Zhiyi Zhang , Shuang Liu , Xiaoning Du, and Junjie Chen},
  booktitle    = {Proceedings of the 2023 32th USENIX Security Symposium},
  month        = AUGUEST,
  year         = 2023,
  address      = {ANAHEIM, CA, USA},
}
```

## Set up

The running procedure of FuzzJIT is the same with Fuzzilli.

1. download swift from the swift download page: https://www.swift.org/download/.

```
wget https://download.swift.org/swift-5.7-release/ubuntu2204/swift-5.7-RELEASE/swift-5.7-RELEASE-ubuntu22.04.tar.gz
```
2. uncompress the downloaded file.
```
tar zxvf ./swift-5.7-RELEASE-ubuntu22.04.tar.gz
```
3. export path of swift.
```
export PATH=~/swift-5.7-RELEASE-ubuntu22.04/usr/bin:${PATH}
```
4. check if swift is working.
```
swift --version
```
It should output:
```
Swift version 5.7 (swift-5.7-RELEASE)
Target: x86_64-unknown-linux-gnu
```

## Installation

Download and compile FuzzJIT.

1. download FuzzJIT from GitHub.
```
git clone https://github.com/SpaceNaN/fuzzjit
```

2. Compile the FuzzJIT.
```
swift build [-c release]
```
It should output:
```
Fetching https://github.com/apple/swift-protobuf.git
Fetched https://github.com/apple/swift-protobuf.git (3.81s)
Computing version for https://github.com/apple/swift-protobuf.git
Computed https://github.com/apple/swift-protobuf.git at 1.20.2 (0.13s)
Creating working copy for https://github.com/apple/swift-protobuf.git
Working copy of https://github.com/apple/swift-protobuf.git resolved at 1.20.2
Compiling plugin SwiftProtobufPlugin...
Building for production...
remark: Incremental compilation has been disabled: it is not compatible with wholeremark: Incremental compilation has been disabled: it is not compatible with wholeremark: Incremental compilation has been disabled: it is not compatible with wholeremark: Incremental compilation has been disabled: it is not compatible with wholeremark: Incremental compilation has been disabled: it is not compatible with wholeremark: Incremental compilation has been disabled: it is not compatible with wholeremark: Incremental compilation has been disabled: it is not compatible with whole[21/21] Linking FuzzilliCli
Build complete! (39.76s)
```

## Fuzz JavaScriptCore

Fuzz JavaScriptCore with FuzzJIT.

1. download JavaScriptCore.
```
git clone https://github.com/WebKit/webkit
```
2. Apply Targets/JavaScriptCore/Patches/*.

This step will be a little bit tricky.
When the version does not match, the user needs to manualy apply the patch.

3. Run the Targets/JavaScriptCore/fuzzbuild.sh script in the webkit root directory.

4. FuzzBuild/Debug/bin/jsc will be the JavaScript shell for the fuzzer.

5. fuzz JavaScriptCore.
```
swift run -c release FuzzilliCli --profile=jsc --timeout=500 --storagePath=./jsc/ /path/to/webkit/FuzzBuild/Debug/bin/jsc
```

