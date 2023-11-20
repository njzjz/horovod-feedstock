#!/bin/bash

set -ex

# See https://github.com/horovod/horovod/issues/3956
flatc -c -o horovod/common/wire horovod/common/wire/message.fbs
flatc -c -I . --include-prefix ../common/wire -o horovod/tensorflow horovod/tensorflow/custom_call_config.fbs

if [[ ${cuda_compiler_version} != "None" ]]; then
    export HOROVOD_GPU_OPERATIONS=NCCL
    export HOROVOD_NCCL_LINK=SHARED
    export HOROVOD_CUDA_HOME=/usr/local/cuda
fi
export HOROVOD_WITH_TENSORFLOW=1
export HOROVOD_WITH_PYTORCH=1
# mxnet is not available on conda-forge
# https://github.com/conda-forge/staged-recipes/issues/4447
export HOROVOD_WITHOUT_MXNET=1
export HOROVOD_WITH_MPI=1
# gloo is not avaiable on conda-forge
export HOROVOD_WITHOUT_GLOO=1
if [[ "${target_platform}" == osx-* ]]; then
    # https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi
if [[ "${target_platform}" == osx-arm64 ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -D Tensorflow_OUTPUT=\"2.14.0;${SP_DIR}/tensorflow/include;-L${SP_DIR}/tensorflow -ltensorflow_framework.2;-I${SP_DIR}/tensorflow/include -DEIGEN_MAX_ALIGN_BYTES=64\""
    export CMAKE_ARGS="${CMAKE_ARGS} -D Pytorch_VERSION=2.0.0"
    export CMAKE_ARGS="${CMAKE_ARGS} -D Pytorch_CUDA=OFF -DPytorch_ROCM=OFF"
    export CMAKE_ARGS="${CMAKE_ARGS} -D Pytorch_INCLUDE_DIRS=${SP_DIR}/torch/include"
    export CMAKE_ARGS="${CMAKE_ARGS} -D Pytorch_LIBRARY_DIRS=${SP_DIR}/torch/lib"
    export CMAKE_ARGS="${CMAKE_ARGS} -D Pytorch_LIBRARIES=c10;torch;torch_cpu;torch_python"
    export CMAKE_ARGS="${CMAKE_ARGS} -D Pytorch_CXX11=ON"
fi

# default is -j8
export MAKEFLAGS="-j${CPU_COUNT}"
python -m pip install . -vv
