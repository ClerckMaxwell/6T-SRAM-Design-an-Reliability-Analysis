# 6T SRAM Cell Design and Reliability Analysis

This repository contains the design, characterization, and statistical analysis of a **6-transistor (6T) SRAM cell** in 100nm CMOS technology. The project investigates the trade-off between static stability and power consumption, with a focus on **Data Retention Voltage (DRV)** estimation.

---

## 📌 Project Overview
The analysis is structured into four main phases:
1. **Cell Design & Sizing:** Balancing the internal inverters to achieve a symmetric Voltage Transfer Characteristic (VTC).
2. **Static Stability Analysis:** Evaluation of Hold and Read Static Noise Margins (HSNM/RSNM) using automated extraction methods.
3. **Statistical Scaling:** 7,000-run Monte Carlo simulations across a $V_{DD}$ range ($1V$ to $0.2V$) to model process variations.
4. **Leakage & DRV Estimation:** Identifying the minimum operating voltage to ensure data integrity while minimizing static power.

## 🛠 1. Sizing and Symmetry
The cell sizing was optimized to center the logic threshold at $V_{DD}/2$.
* **Final Dimensions:** $W_p = 0.12 \mu m$ (Pull-up), $W_n = 0.5 \mu m$ (Pull-down), $W_{ax} = 0.12 \mu m$ (Access).
* **Beta Ratio:** The ratio $\beta = W_n / W_{ax}$ was tuned to $4.16$ to ensure a robust Read Margin.

## 📊 2. Static Noise Margin (SNM)
Stability was quantified by inscribing the maximum possible square within the lobes of the "Butterfly Curves."

| Metric (at $V_{DD}=1V$) | Value |
| :--- | :---: |
| **Hold Margin (HSNM)** | 261.0 mV |
| **Read Margin (RSNM)** | 152.0 mV |

A custom MATLAB script was developed to automate this geometric extraction, showing perfect correlation with the **Seevinck Method** performed in LTspice.

## ⚡ 3. Leakage and Power Dissipation
The study analyzed sub-threshold leakage components ($I_{PU}$, $I_{PD}$, $I_{AX}$) as $V_{DD}$ scales.
* **Findings:** The Pull-down network is the primary contributor to static current.
* **Power Savings:** Reducing $V_{DD}$ from $1.0V$ to $0.5V$ decreases total leakage power from $7.5 nW$ to $0.8 nW$, offering nearly a 10x improvement in energy efficiency.

## 📉 4. Data Retention Voltage (DRV)
The DRV was determined by monitoring the failure rate (HSNM < 60mV) during voltage scaling.
* **Statistical Yield:** The design maintains 100% yield down to $0.5V$. 
* **Critical Limit:** The first failures appear at $0.4V$, and the failure rate becomes unacceptable below $0.3V$.
* **Conclusion:** Considering a 100mV safety margin, the **Minimum Safe Supply Voltage** for this cell is **0.5V**.

---

## 📂 Repository Structure
* `/schematics`: LTspice `.asc` files for the 6T cell and Seevinck validation.
* `/matlab`: Scripts for automated SNM extraction and Monte Carlo data processing.

## ⚙️ Tools Used
* **LTspice**: Circuit-level simulation and Monte Carlo analysis.
* **MATLAB**: Numerical analysis and automated parameter extraction.

**Author:** Raffaele Petrolo
