
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
wget https://download.swift.org/swift-5.7-release/ubuntu2204-aarch64/swift-5.7-RELEASE/swift-5.7-RELEASE-ubuntu22.04-aarch64.tar.gz
```
2. uncompress the downloaded file.
```
tar zxvf ./swift-5.7-RELEASE-ubuntu22.04-aarch64.tar.gz
```
3. export path of swift.
```
export PATH=~/swift-5.7-RELEASE-ubuntu22.04-aarch64/usr/bin:${PATH}
```

## 
