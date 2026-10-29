# 🌱 NabhKrishi

### AI-Powered Smart Farming & Agricultural Decision Support Platform

> **Smarter Farming • Better Decisions • Sustainable Future**

NabhKrishi is an AI-powered agricultural decision-support platform designed to help farmers make smarter and more informed decisions using **Artificial Intelligence, Computer Vision, Reinforcement Learning, RAG, LLMs, satellite data, weather information, and farm-level data**.

The platform is designed to be **multi-crop, multilingual, scalable, and farmer-centric**.

---

## 💡 What is NabhKrishi?

NabhKrishi brings multiple agricultural technologies together in one platform.

**Farmer → Farm & Crop Information → AI Analysis → Decision Support → Agricultural Knowledge → Personalized Guidance → Better Farming**

The goal is to make advanced AI technology easier and more accessible for farmers while supporting productive and sustainable agricultural practices.

---

## ✨ Key Features

### 🔬 AI-Based Crop Disease Detection

NabhKrishi uses a **Swin Transformer (Swin-T)** based computer vision model to analyze crop images and identify potential crop diseases and health conditions.

**Features include:**

- 📷 Crop image analysis
- 🦠 Disease classification
- 📊 Prediction confidence
- 🌱 Crop-health insights
- 🔄 Extensible architecture for additional crops and disease classes

---

### 🤖 AI Decision Support

NabhKrishi integrates a **PPO-based Reinforcement Learning decision-support system**.

It considers contextual information such as:

- 🌱 Crop growth stage
- 🦠 Disease information
- 📊 Prediction confidence
- 🌦️ Environmental conditions
- 💧 Irrigation requirements
- 📈 Agricultural information

The system provides **decision support** to assist farmers and does not replace agricultural experts.

---

### 🧠 AI Agricultural Chatbot

NabhKrishi includes an AI-powered agricultural assistant using:

- **NVIDIA Nemotron**
- **Retrieval-Augmented Generation (RAG)**
- **ChromaDB**
- **BGE Embeddings**

The chatbot retrieves relevant agricultural knowledge before generating a response.

### RAG Pipeline

**User Question → Language Detection → Translation / Normalization → Vector Retrieval → ChromaDB → Relevant Knowledge → Nemotron → Grounded Response → Preferred Language**

This approach helps reduce unsupported or hallucinated agricultural recommendations.

---

## 🌐 Multilingual Support

NabhKrishi is designed to make agricultural information accessible in the farmer's preferred language.

**Supported languages:**

- 🇬🇧 English
- 🇮🇳 Hindi
- 🗣️ Hinglish
- Punjabi
- Haryanvi
- Bengali

The architecture can be extended to support additional regional languages.

---

## 🗺️ Smart Farm Mapping

NabhKrishi allows farmers to digitally define their farm boundaries using GPS and interactive maps.

**Features:**

- 📍 GPS-based location
- 🗺️ Interactive 2D map
- ✏️ Farm boundary drawing
- 📐 Farm area calculation
- 🌍 GeoJSON representation
- 💾 Farm-boundary persistence

This creates a digital representation of the farm that can support future satellite and farm-level analytics.

---

## 🛰️ Satellite & Environmental Data

NabhKrishi is designed to integrate multiple agricultural data sources:

- 🛰️ Satellite observations
- 🌦️ Weather data
- 🌧️ Rainfall
- 🌡️ Temperature
- 🌱 Soil information
- 🚜 Farm-level data
- 🌾 Crop information

These sources can be combined to provide more contextual agricultural decision support.

---

## 🌱 Sustainable Agriculture

NabhKrishi focuses not only on productivity but also on sustainable resource management.

The platform supports:

- 💧 Better water management
- 🌱 Soil management
- 🧪 Input management
- 🌾 Crop management
- ♻️ Sustainable farming practices

The long-term goal is to help farmers improve resource efficiency while building more productive and resilient farming systems.

---

## 🌍 Carbon Credits & MRV

NabhKrishi explores how digital agricultural data can support **Measurement, Reporting and Verification (MRV)** for sustainable farming outcomes.

**Satellite Data + Soil Data + Weather Data + Farm Data**

↓

**NabhKrishi MRV**

↓

**Measure → Report → Verify**

↓

**Verified Agricultural Outcomes**

↓

**Potential Carbon Credit Eligibility**

↓

**Potential Additional Farmer Revenue**

Carbon-credit generation depends on applicable methodologies, verification requirements, standards, and market conditions.

---

# 🏗️ System Architecture

```text
                         ┌─────────────────────┐
                         │       FARMER        │
                         │   Flutter Mobile    │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       FastAPI       │
                         │       Backend       │
                         └──────────┬──────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
              ▼                     ▼                     ▼
       ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
       │   Swin-T    │       │     PPO     │       │     RAG     │
       │  Vision AI  │       │ Decision AI │       │  Knowledge  │
       └─────────────┘       └─────────────┘       └──────┬──────┘
                                                          │
                                                          ▼
                                                  ┌─────────────┐
                                                  │  Nemotron   │
                                                  │     LLM     │
                                                  └──────┬──────┘
                                                         │
                                                         ▼
                                              Multilingual Guidance


