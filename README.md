# CoreVision: Heterogeneous SoC Vision Accelerator
 
## Overview
 
CoreVision is a hardware-software co-design project that implements a custom **AXI-Stream 2D Convolution Engine** on the Xilinx Pynq Z2 System-on-Chip (SoC), targeting real-time edge AI and computer vision applications.
 
The accelerator leverages a highly pipelined Verilog datapath to execute 2D convolution operations in under 5 milliseconds, enabling feature extraction tasks such as edge detection and Gaussian blurring. By coupling physical DSP-slice acceleration with a Python/PYNQ software orchestration layer, the system demonstrates key heterogeneous compute concepts including DMA memory management, AXI streaming protocols, and software compensation techniques for hardware limitations.
 
---
 
## Table of Contents
1. [Key Features](#key-features)
2. [Tech Stack & Materials](#tech-stack--materials)
3. [System Architecture](#system-architecture)
4. [Implementation Phases](#implementation-phases)
5. [Challenges & Solutions](#challenges--solutions)
6. [Usage & Benchmarks](#usage--benchmarks)
7. [Future Scope: CNN Restoration](#future-scope-cnn-image-restoration)
8. [Gallery](#gallery)
---
 
## Key Features
 
- **CPU-Bypassing DMA Pipeline:** Instead of forcing the ARM processor to transfer image pixels sequentially — a significant bottleneck — the system implements a Direct Memory Access (DMA) highway via AXI4-Stream. This allows the entire image to be streamed from DDR memory directly into the custom silicon in one continuous burst, completely freeing the CPU for other tasks during hardware execution.
- **True Reprogrammable SoC Design:** The system is not locked to a single operation. By exposing control registers through memory-mapped AXI4-Lite interfaces and a Python orchestration layer, the active convolution kernel (e.g., Blur, Laplacian, Sobel) and the target image resolution can both be swapped dynamically at runtime — without re-synthesizing or re-flashing the bitstream.
- **Push-Button Pipelined Execution:** The hardware datapath functions as a continuous, high-speed assembly line. Once the software writes the configuration registers, a single "master start" command in Python triggers autonomous hardware execution. From that point forward, the accelerator processes a new pixel on every rising clock edge without any further CPU involvement.
---
 
## Tech Stack & Materials
 
### Hardware
| Component | Details |
|-----------|---------|
| **Target Board** | Xilinx Pynq Z2 |
| **Processing System (PS)** | ARM Cortex-A9 — runs Python orchestration layer |
| **Programmable Logic (PL)** | Custom Verilog datapath — 9 DSP slices, ~12k LUTs |
| **High-Throughput Bus** | AXI4-Stream — DMA image transfers |
| **Control Bus** | AXI4-Lite — memory-mapped configuration registers |
 
### Software & Tools
| Category | Tools |
|----------|-------|
| **RTL Design** | Xilinx Vivado (Verilog + Block Design) |
| **Software Stack** | PYNQ Framework (Jupyter Notebooks) |
| **Libraries** | Python, NumPy, OpenCV, Matplotlib |
 
---
 
## System Architecture
 
The system partitions its workload across two compute domains:
 
**1. The Software Orchestrator (ARM Cortex-A9 / Python)**
Responsible for image acquisition and preprocessing via OpenCV, kernel definition, AXI-Lite register configuration, DMA transaction management, and interrupt handling.
 
**2. The Hardware Accelerator (Programmable Logic / Verilog)**
Responsible for all pixel-level computation. The key hardware subsystems are described below.
 
---
 
### The 4-Buffer "Zero Downtime" Line Buffer Strategy
Applying a 3×3 convolution kernel requires simultaneous access to three consecutive image rows. A naive three-buffer design would force the math engine to stall every time a new row is loaded. To eliminate this bottleneck, the design uses **four line buffers**. While the Vector Engine actively consumes data from three buffers, the fourth buffer silently pre-fetches the next image row in the background. This double-buffering strategy completely hides load latency and guarantees the DSP pipeline is never starved for data.
 
### Smart Traffic Control — The Read Controller
A custom Read Controller FSM acts as a flow-control arbiter between the incoming AXI-Stream and the Vector Engine. It implements a bidirectional handshake: if memory cannot deliver data fast enough, the math engine is held in a safe paused state; if the math engine lags, the incoming stream is held via AXI backpressure. This continuous handshake ensures no pixels are dropped or corrupted, even under transient system load.
 
### Dynamic Image Resizing — The AXI4-Lite TLAST Wrapper
Standard hardware accelerators are typically hardcoded to a single fixed image resolution, requiring re-synthesis to change. The `AXIS_Output_Wrapper.v` module solves this by reading a `TOTAL_PIXELS` register written by Python over AXI4-Lite at runtime. The wrapper autonomously counts the pixel stream and asserts the AXI `TLAST` signal at the correct boundary, signaling end-of-frame to the DMA. This allows the same bitstream to process a 256×256 image one run and a 1080p frame the next, with no hardware changes.
 
### Software Compensation for Hardware Limits (V1.x)
The initial hardware datapath was strictly unsigned, which prevented direct application of signed convolution kernels (required for edge detection). Rather than discarding the working silicon, a **Kernel Decomposition** technique was implemented in Python: any signed kernel is mathematically split into two strictly positive sub-kernels. The hardware runs twice — once per sub-kernel — and the results are subtracted in software to reconstruct the correct signed output. This workaround delivered full edge detection capability without modifying the RTL. Native signed arithmetic was subsequently implemented in V2.0.
 
---
 
## Implementation Phases
 
### V1.x — Hardware-Software Co-Design (Two-Pass Compensation)
*Initial version featured an optimized but strictly unsigned hardware datapath.*
 
| Version | Key Change | File Focus |
|---------|-----------|------|
| **V1.0** — Deadlock Fix | Resolved AXI-Stream DMA deadlocks by exposing `TOTAL_PIXELS` via dynamic AXI-Lite registers, bypassing static Vivado GUI parameters. | `AXIS_Output_Wrapper.v` |
| **V1.1** — State Machine Fix | Prevented Vivado Dead Code Elimination (DCE) by widening internal FSM address pointers from 5-bit to 8-bit to correctly handle 256×256 pixel routing. | `Pipelining.v` |
| **V1.2** — Software Compensation | Implemented Python-level Kernel Decomposition. Signed edge-detection matrices are split into positive sub-arrays; the hardware runs twice and results are combined in software. | `Two_Pass_Edge_Detection.py` |
 ---
 
## Challenges & Solutions
 
| Challenge | Solution |
|-----------|---------|
| **AXI-Stream DMA Deadlocks** | Exposed the `TOTAL_PIXELS` parameter as a runtime-writable AXI-Lite register rather than a static synthesis parameter, allowing the DMA to correctly identify frame boundaries. |
| **Vivado Dead Code Elimination** | Widened FSM state pointers from 5-bit to 8-bit, providing enough address space to prevent the synthesizer from pruning logic paths as unreachable. |
| **Unsigned Silicon with Signed Kernels** | Implemented mathematical kernel decomposition in Python to split signed matrices into positive sub-kernels, running two hardware passes and recombining in software. |
| **DSP Pipeline Starvation** | Adopted a 4-buffer line buffer strategy, hiding row-load latency behind active computation to keep the DSP pipeline continuously fed. |
| **Fixed-Resolution Hardware** | Designed the AXI4-Lite TLAST Wrapper to read a software-defined pixel count at runtime, making the accelerator resolution-agnostic without re-synthesis. |
 
---
 
## Usage & Benchmarks
 
### Setup
1. Flash `design_1.bit` and `design_1.hwh` to the Zynq board via the PYNQ web interface.
2. Open the provided Jupyter Notebook on the board.
3. Define a 3×3 convolution kernel (e.g., Gaussian Blur, Laplacian Edge Detection, Sobel).
4. Load a grayscale image and stream it through the AXI DMA using the notebook cells.
### Performance Metrics (256×256 Grayscale Image)
 
| Metric | Value |
|--------|-------|
| **Pure Silicon Compute Time** | ~4.99 ms |
| **Full System Time** (DMA + Python overhead) | ~12.5 ms |
| **Estimated Throughput** | ~80+ FPS |
| **DSP Slices Used** | 9 |
| **LUT Utilization** | ~12,000 |
 
---
 
## Future Scope: CNN Image Restoration
 
The immediate next step is evolving this architecture from a single-filter feature extractor into a full **End-to-End Edge AI Inference System**.
 
- **CNN Super-Resolution / Restoration:** Deploy a multi-layer Convolutional Neural Network directly on the FPGA to restore degraded or noisy images at the edge, eliminating the need for cloud offload.
- **Systolic Array Upgrade:** Replace the current 9-DSP sliding window with a Systolic Array architecture to scale MAC (Multiply-Accumulate) throughput across deeper network layers.
- **AXI4 Full Burst Transfers:** Optimize memory bandwidth via full AXI4 burst mode to sustain throughput for deeper CNN pipelines without memory starvation.
---
 
## Gallery
 
### Hardware-Accelerated Edge Detection Benchmark
*Extracting Laplacian edges from a 256×256 image in ~5ms using custom Verilog DSP routing.*
 
![FPGA Edge Detection Benchmark](link_to_your_image.jpg)
