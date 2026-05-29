# CoreVision: Heterogeneous SoC Vision Accelerator 🚀

## Description
This project implements a custom **AXI-Stream 2D Convolution Engine** designed for real-time edge AI and computer vision tasks. 

This is a hardware-software co-design project built on the Xilinx Pynq Z2 System-on-Chip (SoC). It utilizes a highly pipelined Verilog datapath to perform convoluation operation in under 5 milliseconds and thus can be used for extracting image features (like edge detection). By combining physical DSP acceleration with a Python/PYNQ orchestration layer, this project demonstrates heterogeneous compute, DMA memory management, and software compensation for hardware limitations.

---

## Table of Contents
1. [Tech Stack & Materials](#tech-stack--materials)
2. [Architecture](#architecture)
3. [Implementation Phases](#implementation-phases)
4. [Usage & Benchmarks](#usage--benchmarks)
5. [Future Scope: CNN Restoration](#future-scope)
6. [Gallery](#gallery)

---

## Tech Stack & Materials

### Hardware 
- **Target Board:** Xilinx Pynq Z2
- **Processing System (PS):** ARM Cortex-A9 (Runs Python orchestration)
- **Programmable Logic (PL):** Custom Verilog datapath (9 DSP slices, ~12k LUTs)
- **Buses:** AXI4-Stream (High-throughput DMA), AXI4-Lite (Control registers)

### Software & Tools
- **RTL Design:** Xilinx Vivado (Verilog + Block Design)
- **Software Stack:** PYNQ Environment (Jupyter Notebooks)
- **Libraries:** Python, NumPy, OpenCV, Matplotlib

---

## Architecture
The system is divided into two partitioned workloads:
1. **The Software Orchestrator (Python):** Handles OpenCV image preprocessing, matrix reshaping and AXI DMA interrupt management.
2. **The Hardware Accelerator (Verilog):** - Uses multi-stage **Line Buffers** to pre-fetch image rows, preventing DSP starvation.
   - Utilizes an **AXI4-Lite Dynamic TLAST Wrapper** to allow software-defined resolution switching (e.g., locking to 64,516 pixels for a 256x256 stream) without re-synthesizing the bitstream.

---

## Implementation Phases

### 🔹 V1.x Hardware-Software Co-Design (Two-Pass Compensation)
*Initial versions featured an optimized but strictly unsigned hardware datapath.*

| Version | Description | File Focus |
|---------|-------------|------|
| ⚙️ V1.0 (Deadlock Fix) | Resolved AXI-Stream DMA deadlocks by exposing `TOTAL_PIXELS` via dynamic AXI-Lite registers, bypassing static Vivado GUI parameters. | `AXIS_Output_Wrapper.v` |
| 🧮 V1.1 (State Machine) | Prevented Vivado Dead Code Elimination (DCE) by upgrading internal state-machine pointers from 5-bit to 8-bit to handle 256x256 routing. | `Pipelining.v` |
| 🔄 V1.2 (Software Comp) | Implemented **Kernel Decomposition** in Python. Split signed edge-detection matrices into strictly positive arrays, running the hardware twice and subtracting in software to bypass unsigned silicon limits. | `Two_Pass_Edge_Detection.ipynb` |

### 🔸 V2.0 Hardware Upgrade (Stable)
*The current stable release with native signed-math support.*

| Version | Description | File Focus |
|---------|-------------|------|
| ⚡ V2.0 (Native Signed) | Upgraded the Verilog Vector Engine to natively cast 9-bit positive pixels and 8-bit signed weights. Enables single-pass, 5ms Edge Detection directly in silicon. | `Vector_Engine.v` |

---

## Usage & Benchmarks
1. Flash the `design_1.bit` and `.hwh` files to the Zynq board via PYNQ.
2. Define a 3x3 Computer Vision Kernel (e.g., Gaussian Blur, Laplacian Edge Detection).
3. Push the image through the AXI DMA using the provided Jupyter Notebook.

### ⏱️ Performance Metrics (256x256 Grayscale)
* **Pure Silicon Math Time:** ~4.99 ms 
* **Full System Time (DMA + Python Overhead):** ~12.5 ms
* **Estimated Pipeline Speed:** ~80+ Frames Per Second (FPS)

---

## 🚀 Future Scope: CNN Image Restoration
The immediate next step for this architecture is evolving it from a single-filter feature extractor into an **End-to-End Edge AI System**. 

**Planned Implementations:**
- 🧠 **CNN Super-Resolution / Restoration:** Deploying a multi-layer Convolutional Neural Network (CNN) to restore noisy/degraded images directly on the FPGA. 
- 🔀 **Systolic Array Upgrade:** Upgrading the 9-DSP sliding window to a Systolic Array architecture to maximize MAC (Multiply-Accumulate) utilization across deeper network layers.
- 💾 **AXI4 Full Burst Transfers:** Optimizing memory bandwidth to feed the deeper CNN pipeline without memory starvation.

---

## 🎥 Gallery

### Hardware-Accelerated Edge Detection Benchmark
*Extracting Laplacian edges in 5 milliseconds using custom Verilog DSP routing.*

*(Upload the before/after McLaren image here and link it!)*
`![FPGA Edge Detection Benchmark](link_to_your_mclaren_image.jpg)`
