# Seren Stress App

**A Real-Time Stress Detection System Using Galvanic Skin Response (GSR) and Flutter Web**

---

# Abstract

Stress is a major physiological and psychological condition that affects human health and productivity. Recent advancements in biosensing technologies and software systems have enabled real-time monitoring of physiological signals for stress detection. This project presents **Seren Stress App**, a Flutter-based web application designed to analyze stress levels using **Galvanic Skin Response (GSR)** signals.

The system uses a **GSR sensor connected to an Arduino microcontroller** to measure variations in skin conductance associated with sympathetic nervous system activity. The collected sensor data is transmitted to a **Flutter web application running on a PC through the Chrome browser**, where signal processing techniques such as **Kalman filtering, normalization, and statistical feature extraction** are applied. The processed data is then analyzed using a **machine learning model** to classify the user's physiological state as stressed or relaxed. The application also provides real-time visualization of the signal using interactive charts.

This project demonstrates how physiological sensing and web-based software platforms can be integrated to develop a practical stress monitoring system.

---

# 1. Introduction

Stress detection using physiological signals has become an important research topic in biomedical engineering and human–computer interaction. One of the most reliable physiological indicators of stress is **Galvanic Skin Response (GSR)**, which measures variations in skin conductance caused by sweat gland activity controlled by the sympathetic nervous system.

The objective of this project is to develop a **real-time stress detection system** that integrates physiological sensing hardware with a **Flutter web-based analysis platform**. The system collects GSR signals using a sensor module connected to an Arduino board, processes the signals using filtering techniques, extracts meaningful features, and predicts stress levels using a machine learning model.

The application runs on a **PC using the Chrome browser**, providing a simple interface for monitoring and analyzing physiological stress signals.

---

# 2. System Architecture

The Seren Stress system consists of four main components:

1. Physiological Signal Acquisition
2. Signal Processing
3. Feature Extraction
4. Stress Classification and Visualization

---

# 3. Hardware Components

The hardware module is responsible for collecting physiological data from the user.

### Components Used

* Arduino Microcontroller
* GSR Sensor Module
* Skin Conductance Electrodes
* USB Serial Communication

### Working Principle

The GSR sensor measures **changes in electrical conductivity of the skin**. When a person experiences stress or emotional arousal, sweat gland activity increases, which increases skin conductance.

The Arduino reads the analog signal from the GSR sensor and converts it into digital values using the ADC. These values are transmitted to the software system for analysis.

---

# 4. Signal Processing

Physiological signals often contain noise due to environmental factors, sensor instability, and motion artifacts. Therefore, signal preprocessing is necessary.

## 4.1 Kalman Filtering

A **Kalman Filter** is implemented to smooth the raw GSR signal and reduce measurement noise. This recursive filter estimates the true signal state by combining previous predictions with new sensor measurements.

## 4.2 Signal Normalization

To ensure consistency across different sessions and subjects, the GSR signal is normalized using the following equation:

GSR_normalized = (GSR − GSR_min) / (GSR_max − GSR_min)

Normalization scales the values to a consistent range suitable for machine learning analysis.

---

# 5. Feature Extraction

After preprocessing, statistical features are extracted from the GSR signal. These features represent physiological characteristics that are useful for stress classification.

### Extracted Features

* Mean GSR value
* Standard deviation
* Signal variance
* Peak amplitude
* Signal slope / trend

These features form a **feature vector** that is used as input for the machine learning model.

---

# 6. Stress Classification Model

### Multi-Level Stress Categorization

To provide a more informative stress analysis, the binary prediction results are further mapped into **four stress intensity levels** based on the magnitude and trend of the GSR signal.

The system categorizes the physiological state into the following four classes:

| Class | Stress Level | Description                                                                   |
| ----- | ------------ | ----------------------------------------------------------------------------- |
| 0     | Relaxed      | Indicates a stable physiological state with low sympathetic nervous activity. |
| 1     | Mid          | Represents mild stress or moderate physiological activation.                  |
| 2     | High         | Indicates significant stress with noticeable increases in skin conductance.   |
| 3     | Very High    | Represents strong physiological stress responses with elevated GSR values.    |

### Classification Workflow

1. Raw GSR data is collected from the sensor.
2. The signal is filtered using a **Kalman Filter**.
3. The filtered signal is normalized.
4. Statistical features are extracted from the signal window.
5. The machine learning model predicts the **binary stress state**.
6. The prediction is mapped into **four stress intensity levels**:
   **Relaxed, Mid, High, and Very High**.

This multi-level classification provides a more **granular interpretation of the user's physiological stress condition**, enabling improved monitoring and analysis.

---

# 7. Flutter Web Application

The user interface and data visualization are implemented using **Flutter Web**.

The application runs locally on a PC using the **Chrome browser**.

### Features

* Real-time GSR signal monitoring
* Live chart visualization of physiological data
* Signal filtering and processing
* Feature extraction
* Stress level prediction
* Session-based stress analysis

---

# 8. Technologies Used

### Software

* Flutter (Web)
* Dart
* Node.js
* HTTP API communication

### Hardware

* Arduino
* GSR Sensor Module

### Signal Processing

* Kalman Filtering
* Data Normalization
* Feature Extraction

### Visualization

* Interactive charts using Flutter libraries


# 9. Installation and Setup

## Step 1 – Clone the Repository

git clone https://github.com/Vishnu-V-Dev-clg/seren_stress_app.git

## Step 2 – Navigate to Project Directory

cd seren_stress_app

## Step 3 – Install Dependencies

flutter pub get

## Step 4 – Run the Flutter Web Application

flutter run -d chrome

The application will open automatically in the **Chrome browser**.

Note: Database Access is not included in this repo, contact authorities for the access.

---

# 10. Applications

This system can be used in several domains:

* Stress monitoring systems
* Mental health research
* Human-computer interaction studies
* Biomedical signal analysis
* Wearable health technology research

---

# 11. Future Work

Possible improvements for the system include:

* Integration with wearable devices
* More advanced machine learning models
* Multi-sensor physiological analysis (Heart Rate, ECG, Temperature)
* Cloud-based stress monitoring
* Personalized stress baseline calibration

---

# 12. Conclusion

This project presents a **Flutter web-based stress detection system using Galvanic Skin Response signals**. The integration of physiological sensing hardware, signal processing techniques, and machine learning algorithms enables real-time stress analysis. By leveraging the cross-platform capabilities of Flutter Web, the system provides an accessible and interactive platform for monitoring physiological stress signals directly through a web browser.

GitHub
https://github.com/Vishnu-V-Dev-clg
