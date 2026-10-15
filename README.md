# Interpolation for Smooth Reconstruction of Sensor Signals

A **Digital Signal Processing (DSP) mini-project** implemented in MATLAB to compare different interpolation techniques for reconstructing downsampled sensor signals.

## Overview

This project compares five interpolation methods:

- Zero-Order Hold
- Linear Interpolation
- Cubic Spline Interpolation
- FFT-Based (Sinc) Interpolation
- Polyphase FIR Interpolation

The methods are evaluated using synthetic sensor signals and real audio data, with performance measured using RMSE, MAE, and correlation coefficient.

## Key Results

- Cubic spline, FFT-based, and polyphase FIR interpolation achieved better reconstruction accuracy than linear interpolation.
- Polyphase FIR reduced RMSE by approximately **42% compared with linear interpolation** on the tested audio signal at a downsampling factor of 8.
- Anti-aliasing filter effectiveness depends on the signal and downsampling factor.

## Technologies Used

- MATLAB
- Signal Processing Toolbox
- Digital Signal Processing (DSP)

## Repository Contents

- `README.md` — Project overview and results
- `DSP_Mini_Project_Report.pdf` — Detailed project report
- `DSP_Mini_Project_Presentation.pptx` — Project presentation
- `interpolation_reconstruction.m` — MATLAB implementation

*Replace the example filenames above with your actual filenames.*

## How to Run

1. Clone or download this repository.
2. Open MATLAB and navigate to the project folder.
3. Run the main `.m` script.

## Author

**Rushikesh Gajanan Borade**

B.Tech. Electronics and Communication Engineering  
DES Pune University, Pune  
Academic Year: 2026–2027
