# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**XaivaKit** is a preset-based Docker build system for the Xaiva Media library - a high-performance media processing framework providing hardware-accelerated video decoding, encoding, image processing, and multiplexing capabilities optimized for NVIDIA GPU environments.

### Technology Stack
- **Base**: Ubuntu 22.04 with CUDA 11.8/cuDNN 8
- **Languages**: C++17 with CUDA, Python 3.10
- **Media**: FFmpeg 4.2, OpenCV 4.11.0 (CUDA-enabled)
- **Deep Learning**: PyTorch 2.1.0 with CUDA 11.8
- **Build System**: CMake, Multi-stage Docker
- **Target GPU**: NVIDIA RTX 30xx series (Ampere, Arch 86)

## Key Development Commands

### Building the Project

```bash
# Interactive build (recommended)
python3 scripts/build.py

# Non-interactive build
python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1 --build-type runtime --non-interactive

# List available presets
python3 scripts/build.py --list-presets
```

### Running Tests

```bash
# Run all Xaiva Media tests
cd xaiva-media
./run_test.sh

# Run specific test suite
./bin/XaivaUtilsTest --gtest_output=xml:test_result.xml
./bin/DecoderTest --gtest_output=xml:test_result.xml
./bin/EncoderTest --gtest_output=xml:test_result.xml
./bin/ImageFilterTest --gtest_output=xml:test_result.xml
./bin/MuxerTest --gtest_output=xml:test_result.xml

# Run Python samples
cd samples/python
python3 XaivaDecoder_Single_Stream_MediaFile.py --input_file test.mp4
```

### Building Xaiva Media Library

```bash
# From xaiva-media directory
mkdir -p cmake_build
cd cmake_build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Docker Container Usage

```bash
# Run runtime container with GPU
docker run --rm -it --gpus all xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime /bin/bash

# Run dev container (includes build tools)
docker run --rm -it --gpus all xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-dev /bin/bash
```

## Architecture Overview

### Preset-Based Build System
The project uses JSON presets (`/presets/`) to define build environments. Each preset specifies:
- CUDA/cuDNN versions
- PyTorch version
- Python version and packages
- System dependencies

### Multi-Stage Docker Architecture
1. **Stage 0 (base)**: CUDA runtime setup
2. **Stage 1 (builder)**: Full development environment with compilers
3. **Stage 2 (runtime)**: Minimal production image with only runtime dependencies
4. **Stage 3 (dev)**: Development image with debugging tools

### Xaiva Media Components
Located in `/xaiva-media/src/`:

1. **XaivaDecoder**: Hardware-accelerated video decoding (NVDEC, FFmpeg)
   - Multiple decoder backends: FFmpeg, NVDEC, GStreamer
   - RTSP streaming support
   - Multi-stream processing

2. **XaivaEncoder**: Hardware-accelerated video encoding (NVENC, FFmpeg)
   - H264/H265 encoding
   - MPEG-DASH support
   - Multiple quality presets

3. **XaivaImageProcessor**: CUDA-accelerated image operations
   - Video scaling and cropping
   - Watermark overlay
   - Subtitle burning
   - JPEG encoding

4. **XaivaMuxer**: Container format handling
   - Remuxing capabilities
   - Audio/video synchronization
   - Seeking support

### Python Bindings
All C++ components have Python wrappers via pybind11, located in `XaivaXXXWrapper/` directories.

## Important Technical Notes

### CUDA Context Management
The project recently improved CUDA context handling (2025.05.28) to fix decoder pipeline issues. Ensure proper context initialization when working with GPU operations.

### Memory Optimization
Replaced `torch::full()` with `cudaMemset()` for better performance in tensor initialization.

### Standard Library Paths
Uses FHS-compliant paths (`/usr/local/`) to avoid custom LD_LIBRARY_PATH issues:
- Binaries: `/usr/local/bin/`
- Libraries: `/usr/local/lib/`
- Headers: `/usr/local/include/`
- Resources: `/usr/local/xaiva_media/`

### C++ ABI Compatibility
The project uses C++11 ABI=0 for PyTorch 2.1.0 compatibility:
```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
```

## Environment Setup

1. Copy environment template:
   ```bash
   cp env.template .env
   ```

2. Edit `.env` if needed for private tokens or custom settings

3. For offline deployment:
   ```bash
   # Build online, then export
   docker save xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime > xaiva-kit.tar
   
   # On offline system
   docker load < xaiva-kit.tar
   ```

## Common Development Tasks

### Adding a New Preset
1. Create JSON file in `/presets/`
2. Define CUDA, Python, PyTorch versions
3. List system packages and Python requirements
4. Run `python3 scripts/build.py` to test

### Modifying Xaiva Media
1. Edit source files in `/xaiva-media/src/`
2. Rebuild with CMake
3. Run tests with `./run_test.sh`
4. Test Python bindings in `samples/python/`

### Debugging Build Issues
- Check build logs in Docker output
- Verify CUDA architecture compatibility
- Ensure all dependencies are in preset JSON
- Check CMake configuration in `xaiva-media/CMakeLists.txt`

## Testing Guidelines

### C++ Tests
- Use Google Test framework
- Test files in `/xaiva-media/src/XaivaTest/`
- Run with `./bin/<TestName>`

### Python Tests
- Sample scripts in `/xaiva-media/samples/python/`
- Test with real media files after running `./test_samples_download.sh`
- Use `XaivaArgParse.py` for consistent argument handling

### Performance Testing
- Multi-stream tests available for decoder/encoder
- GPU memory monitoring recommended
- Check CUDA context usage with nvidia-smi