# Keras Experiments

### Notes on compiling Tensorflow with Mac CPU optimizations

Since tensorflow doesn't support GPU computation on Mac OS X starting with 1.2, I was
interested in optimizing tensorflow as much as possible for running on my Mac's CPU
(4GHz Intel Core i7).

First follow [this](https://stackoverflow.com/questions/41293077/how-to-compile-tensorflow-with-sse4-2-and-avx-instructions)

I'm using `bazel 0.13.0`
Downloaded tensorflow from github (version 1.7.1)

```
Please specify the location of python. [Default is /usr/bin/python]:
Found possible Python library paths:
  /Library/Python/2.7/site-packages
Please input the desired Python library path to use.  Default is [/Library/Python/2.7/site-packages]
Do you wish to build TensorFlow with Google Cloud Platform support? [Y/n]: n
No Google Cloud Platform support will be enabled for TensorFlow.
Do you wish to build TensorFlow with Hadoop File System support? [Y/n]: n
No Hadoop File System support will be enabled for TensorFlow.
Do you wish to build TensorFlow with Amazon S3 File System support? [Y/n]:
Amazon S3 File System support will be enabled for TensorFlow.
Do you wish to build TensorFlow with Apache Kafka Platform support? [Y/n]: n
No Apache Kafka Platform support will be enabled for TensorFlow.
Do you wish to build TensorFlow with XLA JIT support? [y/N]: Y
XLA JIT support will be enabled for TensorFlow.
Do you wish to build TensorFlow with GDR support? [y/N]:
No GDR support will be enabled for TensorFlow.
Do you wish to build TensorFlow with VERBS support? [y/N]:
No VERBS support will be enabled for TensorFlow.
Do you wish to build TensorFlow with OpenCL SYCL support? [y/N]:
No OpenCL SYCL support will be enabled for TensorFlow.
Do you wish to build TensorFlow with CUDA support? [y/N]:
No CUDA support will be enabled for TensorFlow.
Do you wish to download a fresh release of clang? (Experimental) [y/N]:
Clang will not be downloaded.
Do you wish to build TensorFlow with MPI support? [y/N]:
No MPI support will be enabled for TensorFlow.
Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native]:
Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]:
Not configuring the WORKSPACE for Android builds.
Preconfigured Bazel build configs. You can use any of the below by adding "--config=<>" to your build command. See tools/bazel.rc for more details.
	--config=mkl         	# Build with MKL support.
	--config=monolithic  	# Config for mostly static monolithic build.
Configuration finished
```

```
bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.1 --copt=-msse4.2 -k //tensorflow/tools/pip_package:build_pip_package
```

Started at 5:45 (approx)

Lots of warnings about FP unit and "both"

[Here](http://www.andrewclegg.org/tech/TensorFlowLaptopCPU.html) it says to remove the -mfpmath=both option.

```
bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 -k //tensorflow/tools/pip_package:build_pip_package
```

Started at 6:00

Failed after an hour with
```
ERROR: /Users/jon/data/sandbox/tensorflow/tensorflow/core/BUILD:2385:1: Couldn't build file tensorflow/core/_objs/core_cpu_impl/tensorflow/core/common_runtime/process_util.o: C++ compilation of rule '//tensorflow/core:core_cpu_impl' failed (Exit 1)
tensorflow/core/common_runtime/process_util.cc:19:10: fatal error: 'omp.h' file not found
#include <omp.h>
```

```
Jons-iMac:tensorflow jon$ /bin/launchctl setenv LIBRARY_PATH /usr/local/opt/libomp/lib
Jons-iMac:tensorflow jon$ /bin/launchctl setenv CPLUS_INCLUDE_PATH /usr/local/opt/libomp/include
```

Didn't work

```
cd third_party
ln -s ... ...
```

```
bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 -k //tensorflow/tools/pip_package:build_pip_package --copt=-Ithird_party
```


In `third_party/toolchains/cpus/arm/CROSSTOOL.tpl`
```
# Enable a few more warnings that aren't part of -Wall.
  #compiler_flag: "-Wthread-safety"
  #compiler_flag: "-Wself-assign"
```

```
BAZEL_USE_CPP_ONLY_TOOLCHAIN=1 bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 -k //tensorflow/tools/pip_package:build_pip_package
```

Couldn't find any way to force compiler to not use `-Wthread-safety` and `-Wself-assign`.  Googling said
that this was experienced by other users.

Reverted to trying build with clang and not --config=mkl.

Getting closer to working but won't compile with an error about toupper.

Google says it's a problem with pyport.h.

Reboot in recovery mode to turn off SIP.

```
crsutil disable
```

Reboot and patch pyport.h (see here)[https://bugs.python.org/review/10910/diff/2561/Include/pyport.h?context=10&column_width=80]

```
bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 -k //tensorflow/tools/pip_package:build_pip_package --verbose_failures
```

Failed trying to import enum

Retrying with python3 in `./configure` step.

This used to not work because site-packages couldn't be found, but I figured out my python3 install
wasn't complete.

Needed to `brew uninstall python3` and `brew install python3`.

```
bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 -k //tensorflow/tools/pip_package:build_pip_package --verbose_failures
```

Finally success.

```
INFO: Elapsed time: 2167.294s, Critical Path: 100.89s
INFO: 7837 processes, local.
INFO: Build completed successfully, 8239 total actions
```

Building wheel

```
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
```

Uninstall tensorflow-1.8.0 that had been installed from pypi

```
. etc/setup_local.sh
pip uninstall tensorflow
```

Moved wheel to more permanent location

```
cd ~/data/sandbox/tensorflow
mkdir builds
cp /tmp/tensorflow_pkg/tensorflow-1.8.0-cp36-cp36m-macosx_10_13_x86_64.whl builds/
```

Added wheel to requirements.txt

```
#tensorflow>=1.8.0
# Install tensorflow built with CPU optimizations
file:///Users/jon/data/sandbox/tensorflow/builds/tensorflow-1.8.0-cp36-cp36m-macosx_10_13_x86_64.whl
```

Reinstall

```
make setup
```

### Next: trying to compile tensorflow with MKL

My system:

macOS High Sierra 10.13.4
Apple LLVM version 9.1.0 (clang-902.0.39.1)
Target: x86_64-apple-darwin17.5.0
Thread model: posix
python 3.6.5
mklml_mac_2018.0.3.20180406.tgz
bazel 0.13.0

Following instructions at <https://github.com/vfx01j/Tensorflow-MKL-Mac>

Followed all instructions for setting up libmklml.dylib etc...

For tensorflow used `git clone https://github.com/tensorflow/tensorflow.git`
This is tensorflow 1.8.0

Modifying the MKL build looks much simpler

Trying with TF_MKL_ROOT

```
./configure

You have bazel 0.13.0 installed.
Please specify the location of python. [Default is /usr/bin/python]: /usr/local/bin/python3
Found possible Python library paths:
  /usr/local/Cellar/python/3.6.5/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages
Please input the desired Python library path to use.  Default is [/usr/local/Cellar/python/3.6.5/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages]
Do you wish to build TensorFlow with Google Cloud Platform support? [Y/n]: n
No Google Cloud Platform support will be enabled for TensorFlow.
Do you wish to build TensorFlow with Hadoop File System support? [Y/n]: n
No Hadoop File System support will be enabled for TensorFlow.
Do you wish to build TensorFlow with Amazon S3 File System support? [Y/n]: Y
Amazon S3 File System support will be enabled for TensorFlow.
Do you wish to build TensorFlow with Apache Kafka Platform support? [Y/n]: n
No Apache Kafka Platform support will be enabled for TensorFlow.
Do you wish to build TensorFlow with XLA JIT support? [y/N]:
No XLA JIT support will be enabled for TensorFlow.
Do you wish to build TensorFlow with GDR support? [y/N]:
No GDR support will be enabled for TensorFlow.
Do you wish to build TensorFlow with VERBS support? [y/N]:
No VERBS support will be enabled for TensorFlow.
Do you wish to build TensorFlow with OpenCL SYCL support? [y/N]:
No OpenCL SYCL support will be enabled for TensorFlow.
Do you wish to build TensorFlow with CUDA support? [y/N]:
No CUDA support will be enabled for TensorFlow.
Do you wish to download a fresh release of clang? (Experimental) [y/N]:
Clang will not be downloaded.
Do you wish to build TensorFlow with MPI support? [y/N]:
No MPI support will be enabled for TensorFlow.
Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native]:
Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]:
Not configuring the WORKSPACE for Android builds.
Preconfigured Bazel build configs. You can use any of the below by adding "--config=<>" to your build command. See tools/bazel.rc for more details.
	--config=mkl         	# Build with MKL support.
	--config=monolithic  	# Config for mostly static monolithic build.
Configuration finished
```

```
TF_MKL_ROOT=/usr/local/lib bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package --verbose_failures
```
Failed trying to find license.txt
Trying again with different MKL_ROOT
```
TF_MKL_ROOT=/usr/local/opt/intel/mklml bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package --verbose_failures
```

Failed with `tensorflow/core/common_runtime/process_util.cc:19:10: fatal error: 'omp.h' file not found`

This is a very recent issue in tensorflow.  See https://github.com/tensorflow/tensorflow/issues/10685

Solution is to try to fake omp.h with MacOS clang.

```
brew install libomp
mkdir -p third_party/libomp
ln -s /usr/local/Cellar/libomp/5.0.1/include/omp.h third_party/libomp/omp.h
TF_MKL_ROOT=/usr/local/opt/intel/mklml bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package --verbose_failures --copt=-Ithird_party/libomp
```

Needed to edit tensor/core/BUILD in two places and got success.

```
TF_MKL_ROOT=/usr/local/opt/intel/mklml bazel build -c opt --config=mkl --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package --verbose_failures
```
