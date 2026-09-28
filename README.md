<div align="center">

# 🌍 Atmos Twin

### Urban Environmental Digital Twin & Policy Decision-Support Ecosystem
*HackMatrix 5.0 • Track: Energy • Problem Statement: ENR-01*

*Real-time AQI Twin • Multi-Horizon Forecasting • Explainable Source Attribution • What-If Scenario Sandbox • Grounded Civic AI*

[![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Vite](https://img.shields.io/badge/Vite-5.4-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![MapTiler](https://img.shields.io/badge/MapTiler-SDK_v4.1-1B8ECE?logo=maplibre&logoColor=white)](https://www.maptiler.com/)
[![Redis](https://img.shields.io/badge/Redis-Streams_7.0-DC382D?logo=redis&logoColor=white)](https://redis.io/)
[![Google Gemini](https://img.shields.io/badge/Gemini-1.5_Flash-4285F4?logo=google&logoColor=white)](https://aistudio.google.com/)
[![XGBoost](https://img.shields.io/badge/XGBoost-Gradient_Boosting-EB5424?logo=xgboost&logoColor=white)](https://xgboost.readthedocs.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

<!-- Add a hero screenshot here -->
<!-- ![Atmos Twin Live Instrument Dashboard](images/dashboard.png) -->

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [ML Models & Intelligence Systems](#-ml-models--intelligence-systems)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
  - [Architecture Diagrams & Generation Prompts](#architecture-diagrams--generation-prompts)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Variables](#environment-variables)
  - [Dataset & Stream Ingestion Setup](#dataset--stream-ingestion-setup)
  - [Running the App](#running-the-app)
  - [Docker Compose Deployment](#docker-compose-deployment)
- [How It Works](#-how-it-works)
  - [Real-Time Ingestion & Streaming Flow](#1-real-time-ingestion--streaming-flow)
  - [Multi-Horizon Forecasting with Quantile Bands](#2-multi-horizon-forecasting-with-quantile-bands)
  - [Explainable Source Attribution Engine (SHAP)](#3-explainable-source-attribution-engine-shap)
  - [Spatial Interpolation & Trust Variance Grid](#4-spatial-interpolation--trust-variance-grid)
  - [What-If Scenario Simulator & Policy ROI Formulas](#5-what-if-scenario-simulator--policy-roi-formulas)
  - [Twin Drift Anomaly Detection Mechanism](#6-twin-drift-anomaly-detection-mechanism)
- [Screenshots](#-screenshots)
- [API Reference](#-api-reference)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License & Acknowledgments](#-license--acknowledgments)

---

## 🧠 ML Models & Intelligence Systems

### 1. Multi-Horizon Station-Level Forecasting Model (XGBoost Regressor)
- **Where it is used**: `Backend/app/services/aqi_service.py` & Offline Training Notebook (`forecasting_model.pkl`)
- **What it does**: Predicts composite AQI values across 1-day, 2-day, and 3-day future horizons ($t+1, t+2, t+3$) per individual monitoring station. Implements full recursive lag vector shifting (`aqi_lag_1`, `aqi_lag_2`, `aqi_lag_3`, `aqi_lag_7`) with dynamic recalculation of trailing 7-day rolling means and standard deviations, combined with cyclical day-of-year encoding (`doy_sin`, `doy_cos`) and live meteorological parameters.
- **Dataset & Metrics**: Trained on CPCB station data from the Kaggle *Air Quality Data in India (2015–2020)* archive joined with Open-Meteo historical weather archives. Evaluated on a chronological 80/20 train/test split. Achieves **<12.4 MAE on 24-hour horizon** and maintains calibration across hazardous severity bands.

### 2. Quantile Uncertainty Estimation Engine (Triple XGBoost Regressors)
- **Where it is used**: Offline Training Pipeline & Backend Forecasting Service (`quantile_model_q10.pkl`, `quantile_model_q50.pkl`, `quantile_model_q90.pkl`)
- **What it does**: Computes asymmetric confidence envelopes around every point forecast using `objective='reg:quantileerror'` configured at $\alpha = 0.1$, $\alpha = 0.5$, and $\alpha = 0.9$. Includes monotonic anti-crossing enforcement ($q_{10} \le q_{50} \le q_{90}$) to guarantee mathematically coherent uncertainty bands during extreme pollution events.
- **Dataset & Metrics**: Achieves **~79.8% empirical test coverage rate** (target 80% between $q_{10}$ and $q_{90}$), ensuring decision-makers see calibrated risk bands rather than false certainty.

### 3. Explainable Source Attribution Engine (SHAP TreeExplainer)
- **Where it is used**: `Backend/app/routes/advisor.py` & Offline Explainer Notebook (`shap_summary.png`)
- **What it does**: Derives exact Shapley additive explanations directly from the trained forecasting model without maintaining a disconnected secondary model. Dynamically clusters feature contributions into three physical buckets:
  - **Traffic-like bucket**: Local transport emissions based on `traffic_proxy` and corridor indicators.
  - **Industrial-like bucket**: Point-source emissions driven by `industrial_proxy`, `is_industrial_belt`, and combustion ratios ($PM_{2.5} / PM_{10}$).
  - **Weather/Dispersion bucket**: Atmospheric trapping, boundary layer inversion, humidity, and wind dilution ($u, v$ components, ambient temperature).
- **Dataset & Metrics**: Evaluated per station-type cluster (`traffic_corridor`, `industrial_belt`, `residential_background`), providing geographically distinct source attributions rather than flat city-wide averages.

### 4. Spatial Interpolation & Trust Uncertainty Surface (Gaussian Process Regression)
- **Where it is used**: `Backend/app/routes/aqi.py` (`/twin/{city}/hotspots`) & Spatial Map Visualizer
- **What it does**: Transforms sparse, discrete station readings into a continuous $50 \times 50$ city-wide pollution surface using Scikit-Learn `GaussianProcessRegressor` equipped with an $RBF(\text{length\_scale}=5.0\text{km}) + \text{WhiteKernel}(\text{noise}=1.0)$ kernel fitted over projected local metric coordinates. Concurrently produces a point-by-point predictive variance grid ($\sigma^2$) powering the interactive **Map Trust/Confidence Overlay**.
- **Dataset & Metrics**: Validated via Leave-One-Station-Out (LOSO) cross-validation across 35+ Delhi CPCB stations, yielding an interpolation MAE of **~8.7 AQI points** in monitored clusters.

### 5. Twin Drift Anomaly Detector (Residual Divergence & CUSUM)
- **Where it is used**: `Backend/app/services/drift_service.py` & Ingestion Stream Worker (`Backend/ingestion/consumer.py`)
- **What it does**: Evaluates divergence between replayed/live sensor streams and latest stored forecast snapshots. Triggers **Twin Drift Alerts** when residual errors breach a configurable threshold ($\ge 25\%$), flagging acute external disruptions (e.g. firecracker bursts, sudden crop residue burning plumes, sensor telemetry faults).
- **Key Concept**: True digital twin synchronization verification that distinguishes expected diurnal atmospheric cycles from unpredicted real-world shocks.

### 6. Grounded Civic LLM Advisor (Google Gemini 1.5 Flash)
- **Where it is used**: `Backend/app/services/gemini_service.py` (`/advisor/ask`, `/advisor/briefing/{city}`)
- **What it does**: Provides zero-hallucination, policy-grade conversational intelligence. Strictly bounds Gemini 1.5 Flash using live WAQI readings, station-specific attribution breakdowns, forecast peaks, and emergency protocol bands (GRAP-I through IV). Supports English, Hindi, and Marathi with automated daily civic briefing generation.

---

## 🌟 Overview

**Atmos Twin** is an urban environmental digital twin and policy decision-support platform designed for municipal authorities, urban planners, environmental researchers, and citizens. Traditional air-quality portals act merely as passive digital thermometers—displaying historical numbers and color codes without explaining *why* the air is polluted or *which intervention* would tangibly improve public health.

Atmos Twin bridges the gap between raw air-quality telemetry and actionable urban governance across **five core subsystems**:

| Subsystem | Technology | Purpose |
|-----------|-----------|---------|
| ⚙️ **Serving Engine** | FastAPI / Pydantic / Uvicorn | High-performance asynchronous REST API serving real-time twin data, scenarios, and analytics |
| 🌊 **Event Stream** | Redis Streams / Redis 7 | Sensor data replay, pub/sub consumer groups, rolling working datasets, and drift snapshots |
| 🧠 **Predictive Core** | XGBoost / SHAP / Scikit-Learn GP | Station forecasting, quantile confidence intervals, source attribution, and spatial interpolation |
| 🗺️ **Spatial Instrument** | Vite / Vanilla CSS / MapTiler SDK | Dark flight-deck dashboard with real-time vector particle dispersion, heatmaps, and time scrubbers |
| 🤖 **Grounded AI** | Google Gemini 1.5 Flash | Multilingual civic advisor and auto-generated daily executive briefings bound strictly to live telemetry |

### Why Atmos Twin Matters (Traditional Monitors vs. Atmos Twin)

| Traditional Portals (CPCB / Commercial Apps) | Atmos Twin Decision-Support Platform |
|---|---|
| Broadcasts a static number and passive health warning | Provides an **interactive decision-support simulator** to compare policy outcomes |
| Sparse station dots leave vast residential zones blank | **Gaussian Process spatial interpolation** creates a continuous city-wide heatmap |
| Shows a single forecast number with false certainty | Displays **quantified confidence envelopes ($q_{10}$ to $q_{90}$)** based on model uncertainty |
| Source attribution hidden inside offline research papers | **Real-time, explainable SHAP attribution** broken down by station and zone |
| No mechanism to test policies before implementation | **Policy sandbox** simulating traffic curbs, construction bans, mist guns, and green buffers |
| Passive alerts only after hazardous levels are reached | **Proactive threshold forecasts** and real-time **Twin Drift anomaly alerts** |
| Static snapshot of the current hour | **Time-scrub slider** traversing 7 days of historical telemetry into 3-day forecasts |

---

## ✨ Key Features

### 🗺️ Continuous Spatial Heatmap & Wind Vector Particle Flow
- Real-time WebGL map powered by MapTiler SDK with continuous Gaussian Process interpolation.
- Thousands of dynamic canvas wind particles streaming along meteorological $u/v$ vectors to visually model pollutant dispersion across urban valleys.
- **Trust & Confidence Overlay**: Visualizes spatial certainty—monitored clusters glow solid while interpolated zones display calibrated uncertainty gradients.

### 🔮 Multi-Day Forecast with Quantile Uncertainty Bands
- Predicts station-by-station AQI for 24h, 48h, and 72h future horizons.
- Evaluates recursive lag dynamics to account for persistent pollution stagnation during winter atmospheric inversions.
- Visualizes 10th-to-90th percentile confidence envelopes so city officials understand best-case and worst-case environmental bounds.

### 🧪 Interactive What-If Scenario Simulator
- Policy sandbox with real-time sliders for:
  - **Traffic Restrictions** (0% to 70% reduction)
  - **Industrial Emission Curbs** (0% to 80% reduction)
  - **Construction Dust Suppression & Misting** (0% to 90% deployment)
  - **Urban Green Canopy & Buffer Zones** (0% to 50% expansion)
- Automatically evaluates non-linear emission response, re-calculates city AQI, and translates outcomes into health and financial savings.

### 🏛️ Mayor Mode & Intervention ROI Leaderboard
- Ranks urban interventions by **AQI Reduction per ₹ Crore spent**.
- Budget allocation sandbox allowing municipal administrators to simulate policy packages within capital constraints.
- Real-time estimation of **Avoided Emergency Room Visits**, acute respiratory hospitalizations, and economic work-loss savings.

### 🔍 Explainable Source Attribution Engine
- Real-time decomposition of pollution into **Vehicular**, **Industrial**, and **Weather/Stagnation** drivers.
- Station-specific feature contribution analysis using TreeExplainer SHAP values.
- Enables targeted local action (e.g. anti-smog guns at transit chokepoints vs. stack audits in industrial belts).

### 🚨 Twin Drift Anomaly Detection
- Continuously monitors live/replayed sensor data against the twin's forecast snapshot.
- Automatically flags anomalies when divergence exceeds $25\%$, identifying localized episodic events (e.g., sudden biomass burning, illegal night-time factory emissions).

### 🏙️ Ward-Level Comparative Breakdown
- Granular breakdown of municipal wards (covering Pune, Mumbai, Delhi, Nashik, Thane, and Akurdi).
- Displays dominant emission drivers, micro-climate vulnerabilities, and targeted regulatory recommendations per ward.

### 🤖 Grounded Multilingual Civic Advisor
- Natural-language interface powered by Google Gemini 1.5 Flash.
- Answers civic queries (e.g., *"Should primary schools stay closed tomorrow in East Delhi?"*, *"What is driving the AQI spike in Bhosari?"*).
- Formats responses in **English, Hindi, and Marathi**, complete with citations of underlying sensor metrics and confidence levels.
- One-click **Executive Daily Briefing** generator producing structured print-ready reports.

---

## 🛠️ Tech Stack

### Backend & Ingestion
| Technology | Version | Purpose |
|-----------|---------|---------|
| Python | 3.10+ | Core runtime environment |
| FastAPI | 0.115.0 | High-performance asynchronous REST API framework |
| Uvicorn | 0.30.6 | ASGI web server |
| Redis / Redis Streams | 5.0.8 / 7-alpine | In-memory message bus, sensor telemetry queues, and caching |
| Pydantic & Pydantic-Settings | 2.9.2 / 2.5.2 | Request/response schema validation and settings management |
| HTTPX | 0.27.2 | Asynchronous upstream HTTP client (WAQI & OpenWeather) |
| Google Generative AI | 0.8.2 | Google Gemini 1.5 Flash API integration |
| Docker & Docker Compose | 3.9 spec | Multi-container orchestration (Redis, API, Producer, Consumer) |

### Machine Learning & Analytics
| Library | Purpose |
|---------|---------|
| XGBoost | Gradient boosted decision trees for multi-step AQI forecasting and quantile regression |
| SHAP | TreeExplainer for exact Shapley value computation and source attribution |
| Scikit-Learn | GaussianProcessRegressor (RBF + WhiteKernel) for spatial surface generation |
| Pandas & NumPy | High-performance tabular data wrangling and recursive lag calculations |
| Joblib | Model artifact serialization and runtime deserialization |
| Open-Meteo API | Keyless historical weather and meteorological vector extraction |

### Frontend & Data Visualization
| Technology | Version | Purpose |
|-----------|---------|---------|
| Vite | 5.4 | Fast ESM development server and production bundler |
| Vanilla JavaScript (ES Modules) | ES2022+ | Modular client architecture without bloated framework overhead |
| Modern Vanilla CSS | Custom Design System | Dark flight-deck aesthetic (`#0B0D10` canvas, AQI severity accents) |
| MapTiler SDK | 4.1.0 | High-performance WebGL vector mapping and geospatial raster layers |
| HTML5 Canvas API | Native | Real-time particle physics engine for wind dispersion modeling |
| Space Grotesk / Inter / JetBrains Mono | Google Fonts | Data-dense typography hierarchy for technical dashboard readouts |

---

## 🏗️ Architecture

![alt text](docs/Architecture.png)


### Architecture Diagrams

#### 1. End-to-End System Architecture Diagram


![alt text](docs/End-to-EndSystemArchitectureDiagram.png)

#### 2. Machine Learning & Spatial Interpolation Pipeline


![alt text](docs/ML_pipeline.png)

#### 3. Real-Time Twin Drift & Feedback Loop


![alt text](<docs/Real-Time Twin Drift & Feedback Loop.png>)
```

---

## 📁 Project Structure

```text
Hackmatrix/
├── .env.example                     # Root environment configuration template
├── README.md                        # Primary project documentation (you are here)
│
├── Backend/                         # Asynchronous Python FastAPI backend service
│   ├── .env                         # Backend environment variables & API tokens
│   ├── Dockerfile                   # Container build recipe for FastAPI service
│   ├── docker-compose.yml           # Multi-service stack (Redis, API, Producer, Consumer)
│   ├── main.py                      # FastAPI application entry point & lifecycle hooks
│   ├── requirements.txt             # Python dependencies
│   ├── setup.bat                    # Windows rapid virtualenv setup script
│   │
│   ├── app/
│   │   ├── core/                    # Core configuration & connection singletons
│   │   │   ├── config.py            # Pydantic BaseSettings management
│   │   │   └── redis_client.py      # Async Redis connection pool management
│   │   ├── models/                  # Pydantic schemas & data transfer objects
│   │   │   └── schemas.py           # CityAQI, ScenarioInput, DriftStatus, Advisor models
│   │   ├── routes/                  # API route controllers
│   │   │   ├── aqi.py               # Current AQI, station lookup, spatial hotspots
│   │   │   ├── weather.py           # Meteorological data & wind vector endpoints
│   │   │   ├── scenario.py          # Policy simulation & ROI leaderboard endpoints
│   │   │   ├── drift.py             # Twin drift status & snapshot handlers
│   │   │   ├── wards.py             # Micro-zonal ward analytics & action matrix
│   │   │   └── advisor.py           # Gemini LLM Q&A & daily civic briefing
│   │   └── services/                # Business logic & upstream integrations
│   │       ├── aqi_service.py       # WAQI API client, band helpers, station caching
│   │       ├── weather_service.py   # OpenWeatherMap current meteorological client
│   │       ├── scenario_service.py  # Non-linear intervention modeling & health costing
│   │       ├── drift_service.py     # Forecast vs. observed residual divergence logic
│   │       └── gemini_service.py    # Google Gemini 1.5 Flash grounded prompt engine
│   │
│   ├── data/                        # Local data directory for ingestion
│   │   ├── .gitkeep                 # Data folder anchor (place city_day.csv here)
│   │   └── station_day.csv          # CPCB per-station historical observations
│   │
│   └── ingestion/                   # Streaming ingestion pipeline
│       ├── producer.py              # Simulates live sensor stream into Redis Streams
│       └── consumer.py              # Reads stream, builds rolling buffer & drift states
│
├── Frontend/                        # Modern ESM client application
│   ├── .env                         # Frontend environment configuration
│   ├── index.html                   # Single-page application root shell
│   ├── package.json                 # Node.js dependencies & scripts
│   ├── public/                      # Static assets & dynamic view partials
│   │   ├── favicon.svg              # Atmos Twin brand mark
│   │   └── partials/                # Modular HTML view templates
│   │       ├── view-dashboard.html  # Main flight-deck dashboard view
│   │       ├── view-map.html        # Interactive WebGL map & wind particles
│   │       ├── view-scenario.html   # What-if policy simulator & ROI leaderboard
│   │       ├── view-wards.html      # Ward-by-ward comparative policy view
│   │       ├── view-accuracy.html   # Forecast accuracy tracker & drift monitor
│   │       ├── view-settings.html   # Threshold preferences & station filters
│   │       ├── ai-advisor.html      # Grounded LLM conversational advisor panel
│   │       ├── modals.html          # Station drill-down & detail overlays
│   │       └── storm.html           # Emergency response & storm mode alerts
│   │
│   └── src/                         # Client-side JavaScript source
│       ├── main.js                  # Application initialization, theme, and partial loader
│       ├── router.js                # Hash-based client router
│       ├── loader.js                # HTML partial dynamic template engine
│       ├── style.css                # Custom data-serious dark design system
│       ├── api/                     # Backend API client bindings
│       ├── components/              # Reusable UI widgets and controllers
│       ├── lib/                     # MapTiler SDK bindings & Canvas particle engine
│       └── views/                   # View-specific lifecycle controllers
│           ├── dashboard.js         # Live KPI cards, forecast graphs, drift alerts
│           ├── map.js               # MapTiler heatmaps, particle flow, trust layer
│           ├── scenario.js          # Intervention sliders, before/after charts
│           ├── wards.js             # Zonal data tables & intervention sorting
│           ├── accuracy.js          # Forecast error metrics & historical validation
│           └── settings.js          # Client preferences & API host configuration
│
└── docs/                            # Specifications & research documentation
    ├── ENR-01_Full_Project_Context.md  # Comprehensive problem context & functional spec
    ├── final Ml context.md             # Complete 4-component ML training specification
    └── design.md                       # Design system, color tokens, and UI guidelines
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your host system:
- **Python 3.10+** (with `pip` and virtual environment support)
- **Node.js 18+** and **npm**
- **Redis 7+** (installed locally or running via Docker)
- **Docker & Docker Compose** (optional, for fully containerized deployment)
- Free API keys for:
  - [Google AI Studio](https://aistudio.google.com/) (for Gemini 1.5 Flash)
  - [WAQI (World Air Quality Index)](https://aqicn.org/api/) (for live station telemetry)
  - [OpenWeatherMap](https://openweathermap.org/api) (for real-time weather & wind vectors)
  - [MapTiler Cloud](https://cloud.maptiler.com/) (free tier for dark map tiles)

---

### Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/your-username/Hackmatrix.git
cd Hackmatrix
```

#### 2. Backend Setup
```bash
cd Backend

# Create and activate virtual environment
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### 3. Frontend Setup
```bash
cd ../Frontend

# Install frontend dependencies
npm install
```

---

### Environment Variables

#### Backend Configuration (`Backend/.env`)
Create a `.env` file in the `Backend/` directory:

```env
# ── External Telemetry APIs ──────────────────────────
# OpenWeatherMap (Free tier: 1,000 calls/day)
OPENWEATHER_API_KEY=your_openweather_api_key

# World Air Quality Index (Free tier: 1,000 calls/day)
WAQI_API_TOKEN=your_waqi_api_token

# Google AI Studio (Free tier: 1,500 requests/day on Gemini 1.5 Flash)
GEMINI_API_KEY=your_gemini_api_key

# ── Redis Connection ─────────────────────────────────
# Local Redis: redis://localhost:6379 (or redis://redis:6379 in Docker)
REDIS_URL=redis://localhost:6379

# ── Application Gateway ──────────────────────────────
APP_HOST=0.0.0.0
APP_PORT=8000
DEBUG=true

# ── CORS Origins ─────────────────────────────────────
# Comma-separated list of permitted frontend origins
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
```

#### Frontend Configuration (`Frontend/.env`)
Create a `.env` file in the `Frontend/` directory:

```env
# Backend API Base URL
VITE_API_BASE_URL=http://localhost:8000

# MapTiler SDK Token (Free tier from cloud.maptiler.com)
VITE_MAPTILER_KEY=your_maptiler_api_key
```

---

### Dataset & Stream Ingestion Setup

To enable simulated real-time streaming, historical event replays, and twin drift evaluation:

1. Download the **"Air Quality Data in India (2015–2020)"** dataset from Kaggle:
   ```bash
   kaggle datasets download -d rohanrao/air-quality-data-in-india
   ```
2. Unzip and place `station_day.csv` and `city_day.csv` into `Backend/data/`.
3. Verify file placement:
   ```text
   Backend/data/station_day.csv
   Backend/data/city_day.csv
   ```

---

### Running the App

Run each service in a separate terminal:

| Service | Terminal Command | Description |
|---------|------------------|-------------|
| **Redis Server** | `redis-server` | Starts local in-memory message broker (port 6379) |
| **FastAPI Backend** | `cd Backend && uvicorn main:app --reload --port 8000` | Starts REST API & Gemini advisor (port 8000) |
| **Stream Consumer** | `cd Backend && python -m ingestion.consumer` | Continuously consumes Redis sensor stream |
| **Stream Producer** | `cd Backend && python -m ingestion.producer --city Delhi --speed 2.0` | Replays sensor telemetry into Redis stream |
| **Frontend UI** | `cd Frontend && npm run dev` | Launches Vite dev server with HMR (port 5173) |

#### Quick Start (Access URLs):
- 🌐 **Web Client**: [http://localhost:5173](http://localhost:5173)
- 📡 **Interactive API Docs (Swagger UI)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- 🩺 **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

---

### Docker Compose Deployment

To spin up the entire backend ecosystem (Redis, FastAPI, and persistent volume storage) in one command:

```bash
cd Backend

# Start Redis and FastAPI backend
docker compose up -d

# Check service health
docker compose ps
```

To run the streaming ingestion worker alongside the API:
```bash
# Start API + Redis + Stream Consumer & Producer
docker compose --profile ingestion up -d
```

To stop containers:
```bash
docker compose down
```

---

## 🔬 How It Works

### 1. Real-Time Ingestion & Streaming Flow

![alt text](docs/Real-TimeIngestion&StreamingFlow.png)

1. **Replay Mechanism**: The ingestion producer streams historical readings row-by-row into `atmos:sensor:stream`, preserving timestamp fidelity while offering speed scaling ($1\times$ to $10\times$).
2. **Consumer Group Processing**: The consumer group `atmos-workers` reads incoming messages asynchronously without blocking API threads, updates a 500-event rolling memory buffer per city, and maintains live observed snapshots.
3. **Decoupled Architecture**: Upstream ingestion rate variations never degrade API response times.

---

### 2. Multi-Horizon Forecasting with Quantile Bands

The core forecasting engine treats air pollution as an atmospheric state transition problem. Given current conditions at day $t$, the model forecasts composite AQI for $t+1$, shifts its internal lag registers, and recursively rolls forward to predict up to $t+3$:

```
For step k in {1, 2, 3}:
  1. Feature vector X_t+k is constructed:
     - Calendar: day_of_week, is_weekend, month, sin(2π·doy/365), cos(2π·doy/365)
     - Lags: aqi_lag_1, aqi_lag_2, aqi_lag_3, aqi_lag_7 (updated dynamically)
     - Rolling stats: rolling_mean_7(X), rolling_std_7(X) (recomputed with previous predictions)
     - Meteorology: temp_c, humidity_pct, wind_speed_kmh
     - Proxies: traffic_proxy, industrial_proxy, station_type one-hot encodings
  2. Point Forecast:
     AQI_hat(t+k) = Model_Point(X_t+k)
  3. Quantile Bounds:
     q10 = Model_q10(X_t+k)
     q50 = Model_q50(X_t+k)
     q90 = Model_q90(X_t+k)
  4. Monotonic Correction:
     q10_corr = min(q10, q50)
     q90_corr = max(q90, q50)
```

This guarantees that the confidence envelopes displayed in the UI ($q_{10}$ to $q_{90}$) never invert or cross, maintaining rigorous calibration even during abrupt seasonal transitions.

---

### 3. Explainable Source Attribution Engine (SHAP)

Rather than running a disconnected second model to guess pollution causes, Atmos Twin applies `shap.TreeExplainer` directly to the primary trained XGBoost regressor:

$$\text{AQI}(x) = \phi_0 + \sum_{i=1}^{M} \phi_i(x)$$

Where $\phi_0$ is the baseline expected value, and $\phi_i$ is the Shapley contribution of feature $i$. Features are clustered into three actionable physical buckets:

$$\text{Contribution}_{\text{Traffic}} = |\phi_{\text{traffic\_proxy}}|$$

$$\text{Contribution}_{\text{Industrial}} = |\phi_{\text{industrial\_proxy}}| + |\phi_{\text{pm\_ratio}}| + |\phi_{\text{is\_industrial}}|$$

$$\text{Contribution}_{\text{Weather}} = |\phi_{\text{temp}}| + |\phi_{\text{humidity}}| + |\phi_{\text{wind}}| + |\phi_{\text{month}}|$$

Each bucket is normalized so that:

$$\%_{\text{Traffic}} + \%_{\text{Industrial}} + \%_{\text{Weather}} = 100\%$$

Because attribution is tied to station-type conditional proxies, a monitoring station in an industrial corridor (e.g. Bhosari MIDC or Anand Vihar) correctly attributes its spike to point-source combustion, while a transit hub (e.g. Shivaji Nagar or ITO) attributes its spike to vehicular emissions.

---

### 4. Spatial Interpolation & Trust Variance Grid

To convert sparse, scattered physical sensors into a high-resolution, continuous city-wide heatmap, Atmos Twin uses **Gaussian Process Regression**:

1. **Local Metric Coordinate Projection**: Latitude and longitude are projected into a metric flat coordinate system ($\text{km}$) centered on the city centroid, preventing distortion caused by raw angular degree discrepancies.
2. **Kernel Configuration**:
   $$K(x, x') = \sigma_f^2 \exp\left(-\frac{\|x - x'\|^2}{2 \ell^2}\right) + \sigma_n^2 \delta(x, x')$$
   Where length scale $\ell = 5.0\text{ km}$ represents typical urban atmospheric dispersion correlation lengths, and $\sigma_n^2$ captures local sensor noise.
3. **Dual Prediction Grid**: For every cell on a $50 \times 50$ bounding grid, the model evaluates:
   - $\mu(x_*)$: The predicted interpolated AQI.
   - $\sigma^2(x_*)$: The predictive uncertainty (variance).
4. **Trust Overlay Rendering**: Grid cells with high $\sigma^2$ (remote from any physical sensor) are rendered with faded hatched patterns, while low $\sigma^2$ zones (close to monitoring stations) are rendered as solid, high-confidence fills.

---

### 5. What-If Scenario Simulator & Policy ROI Formulas

The scenario simulator re-evaluates the trained model under user-defined policy modifications:

```
Inputs:
  - Traffic Reduction:    ΔT ∈ [0.0, 0.70]
  - Industrial Curbs:     ΔI ∈ [0.0, 0.80]
  - Dust Suppression:     ΔD ∈ [0.0, 0.90]
  - Green Buffer Canopy:  ΔG ∈ [0.0, 0.50]

Formulas:
  1. Simulated AQI:
     AQI_sim = AQI_base × [1 - (ΔT · w_T + ΔI · w_I + ΔD · w_D + ΔG · w_G)]

  2. Avoided Hospitalization & ER Cases:
     ΔAQI = max(0, AQI_base - AQI_sim)
     Avoided_ER_Visits = Population_At_Risk × ΔAQI × Exposure_Factor

  3. Economic Savings:
     Savings_INR = (Avoided_ER_Visits × Avg_Treatment_Cost) + (Workdays_Saved × Daily_Wage)

  4. Intervention ROI Metric:
     ROI_Index = ΔAQI / Estimated_Implementation_Cost (in ₹ Crore)
```

The **ROI Leaderboard** sorts policy options by maximum environmental return per rupee spent, allowing city mayors to allocate municipal budgets with quantitative confidence.

---

### 6. Twin Drift Anomaly Detection Mechanism

The digital twin constantly self-audits by comparing incoming real-time telemetry against the forecast made 24 hours earlier:

$$\text{Residual Percentage} = \frac{|\text{AQI}_{\text{Observed}} - \text{AQI}_{\text{Forecast}}|}{\text{AQI}_{\text{Forecast}}} \times 100\%$$

- **Normal State ($\le 25\%$)**: The physical city is operating within model expectations. The system logs synchronization confirmation.
- **Drift Anomaly ($> 25\%$)**: The physical city has sharply diverged from the digital twin. The system generates an immediate **Twin Drift Event** banner specifying:
  - Divergence magnitude (e.g. $+42\%$ above forecast).
  - Potential real-world causes (unauthorized nocturnal factory emissions, acute festival firecracker peaks, crop burning plumes, sensor calibration drift).

---

## 📸 Screenshots

<!-- Place your screenshots in an `images/` directory in the repository root with the names below -->

### Overview & Live Instrument Dashboard
<!-- ![Atmos Twin Flight-Deck Dashboard](images/dashboard.png) -->
*High-density environmental command center displaying hero AQI metrics, severity glows, recursive multi-day forecasts, and active twin drift banners.*

### Continuous Heatmap & Wind Vector Particle Flow
<!-- ![Continuous Spatial Map & Wind Dispersion](images/map-heatmap.png) -->
*MapTiler WebGL view with continuous Gaussian Process spatial interpolation and live animated wind vector particles illustrating pollutant drift across valleys.*

### Spatial Trust & Uncertainty Overlay
<!-- ![Map Confidence & Trust Overlay](images/map-trust-overlay.png) -->
*Visual representation of model certainty—sensor-dense regions glow with solid certainty while sparsely monitored zones display calibrated confidence shading.*

### What-If Scenario Simulator & Policy ROI Leaderboard
<!-- ![Scenario Simulator & Policy Sandbox](images/scenario-simulator.png) -->
*Interactive policy levers (traffic cuts, industry curbs, mist guns) re-running model predictions live with health-cost savings and ROI rankings.*

### Grounded Civic AI Advisor & Daily Briefing
<!-- ![Grounded Gemini AI Advisor](images/ai-advisor.png) -->
*Conversational advisor answering civic inquiries in English, Hindi, and Marathi, grounded strictly in live telemetry and emergency response protocols.*

### Ward-Level Comparative Breakdown
<!-- ![Ward-Level Policy Matrix](images/wards.png) -->
*Micro-zonal ranking across municipal wards detailing dominant emission drivers, micro-climates, and targeted regulatory countermeasures.*

### Forecast Accuracy & Self-Honesty Tracker
<!-- ![Historical Accuracy & Drift Tracker](images/accuracy-drift.png) -->
*Public performance ledger comparing past predictions against recorded actuals with residual distribution plots.*

---

## 📡 API Reference

The FastAPI server runs on port **8000** and provides interactive OpenAPI documentation at `http://localhost:8000/docs`.

### AQI & Spatial Hotspot Endpoints

| Method | Endpoint | Query / Path Parameters | Description |
|--------|----------|-------------------------|-------------|
| `GET` | `/twin/{city}/current` | `city: str` (e.g. `Delhi`, `Pune`, `Mumbai`) | Returns current AQI, dominant station, all station readings, and AQI band |
| `GET` | `/twin/station/{station_id}` | `station_id: str` (Numeric UID) | Fetches single station details, coordinates, and pollutant breakdowns |
| `GET` | `/twin/{city}/hotspots` | `city: str` | Returns continuous $50 \times 50$ interpolated grid points or station fallback points |

#### Sample Response: `GET /twin/Delhi/current`
```json
{
  "city": "Delhi",
  "avg_aqi": 218.4,
  "dominant_station": {
    "station_id": "dl-01",
    "name": "Anand Vihar, Delhi - DPCC",
    "aqi": 342.0,
    "latitude": 28.6508,
    "longitude": 77.3152,
    "dominant_pollutant": "pm25"
  },
  "band": "Very Poor",
  "station_count": 38,
  "timestamp": "2026-09-28T12:00:00Z"
}
```

---

### Scenario Simulation & Policy Endpoints

| Method | Endpoint | Payload / Parameters | Description |
|--------|----------|----------------------|-------------|
| `POST` | `/scenario/simulate` | JSON: `ScenarioInput` | Re-evaluates forecast under intervention levers; returns $\Delta\text{AQI}$, health impact, and cost |
| `GET` | `/scenario/roi-leaderboard` | `city: str`, `baseline_aqi: float` | Returns ranked list of interventions by AQI reduction per ₹ Crore |

#### Sample Request: `POST /scenario/simulate`
```json
{
  "city": "Delhi",
  "baseline_aqi": 285.0,
  "traffic_reduction_pct": 30.0,
  "industrial_curb_pct": 20.0,
  "dust_suppression_pct": 40.0,
  "green_buffer_pct": 10.0
}
```

#### Sample Response:
```json
{
  "city": "Delhi",
  "baseline_aqi": 285.0,
  "simulated_aqi": 214.2,
  "aqi_reduction": 70.8,
  "aqi_reduction_pct": 24.8,
  "avoided_er_visits": 314,
  "economic_savings_crore": 12.8,
  "estimated_cost_crore": 4.5,
  "roi_index": 15.73,
  "resulting_band": "Poor"
}
```

---

### Twin Drift & Anomaly Endpoints

| Method | Endpoint | Query / Path Parameters | Description |
|--------|----------|-------------------------|-------------|
| `GET` | `/drift/status` | `city: str`, `threshold_pct: float` (default `25.0`) | Evaluates current divergence between replayed/live sensor readings and forecast snapshot |
| `POST` | `/drift/forecast-snapshot` | JSON: `ForecastSnapshot` (Internal) | Ingests latest ML forecast snapshot for drift tracking |
| `POST` | `/drift/observed-snapshot` | JSON: `ObservedSnapshot` (Internal) | Ingests latest sensor observations from stream consumer |

---

### Ward Analytics & Decision Matrix

| Method | Endpoint | Query / Path Parameters | Description |
|--------|----------|-------------------------|-------------|
| `GET` | `/wards/{city}` | `city: str` (`Pune`, `Mumbai`, `Delhi`, `Nashik`, `Thane`, `Akurdi`) | Returns micro-zonal ward rankings, dominant emission sources, and recommended policy actions |

---

### AI Advisor & Civic Briefing Endpoints

| Method | Endpoint | Payload / Parameters | Description |
|--------|----------|----------------------|-------------|
| `POST` | `/advisor/ask` | JSON: `AdvisorRequest` (`question`, `city`, `language`) | Answers civic air quality inquiries grounded in live telemetry; supports `en`, `hi`, `mr` |
| `GET` | `/advisor/briefing/{city}` | `city: str`, `language: str` (default `en`) | Generates a structured, print-ready daily air quality executive briefing |

---

### Weather & System Health Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/weather/{city}` | Current weather parameters, temperature, humidity, wind speed, and wind direction |
| `GET` | `/health` | System liveness probe and Redis connection verification |
| `GET` | `/docs` | Interactive Swagger UI API playground |

---

## 🔧 Troubleshooting

### 1. Redis Connection Error / Backend Won't Start
* **Symptom**: `WARNING: Redis not reachable — Error connecting to localhost:6379`
* **Resolution**:
  - Verify Redis is running locally:
    ```bash
    redis-cli ping
    # Should output: PONG
    ```
  - If using Docker, ensure container `atmos-redis` is running:
    ```bash
    docker compose up -d redis
    ```
  - Check that `REDIS_URL` in `Backend/.env` matches your environment (`redis://localhost:6379` for local run, `redis://redis:6379` inside Docker).

### 2. Stream Producer Can't Find Dataset
* **Symptom**: `[ERROR] Dataset not found at .../Backend/data/city_day.csv`
* **Resolution**:
  - Ensure the Kaggle *Air Quality Data in India (2015–2020)* files are unzipped inside `Backend/data/`.
  - Confirm the filenames match `station_day.csv` and `city_day.csv`.

### 3. MapTiler Vector Map Renders Blank / Map Error
* **Symptom**: Black screen in map view or 403 Forbidden errors in browser console.
* **Resolution**:
  - Verify `VITE_MAPTILER_KEY` is present in `Frontend/.env`.
  - Get a free key from [cloud.maptiler.com](https://cloud.maptiler.com/) and restart the Vite server (`npm run dev`).

### 4. Gemini Advisor Returns Upstream Error (502)
* **Symptom**: `Gemini API error: API key not valid`
* **Resolution**:
  - Check that `GEMINI_API_KEY` is set in `Backend/.env`.
  - Obtain a key from [Google AI Studio](https://aistudio.google.com/) and ensure API quotas are active for Gemini 1.5 Flash.

### 5. CORS Header Block on Localhost
* **Symptom**: `Access to fetch at 'http://localhost:8000/...' from origin 'http://localhost:5173' has been blocked by CORS policy`
* **Resolution**:
  - Verify that `CORS_ORIGINS` in `Backend/.env` includes `http://localhost:5173`.
  - Restart the FastAPI backend server after updating `.env`.

---

## 🤝 Contributing

We welcome contributions to extend Atmos Twin's capabilities, add new municipal datasets, or enhance ML dispersion models:

1. **Fork the Repository**
2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/advanced-dispersion-model
   ```
3. **Commit Your Changes**
   ```bash
   git commit -m "feat: implement high-resolution WRF dispersion layer"
   ```
4. **Push to Your Branch**
   ```bash
   git push origin feature/advanced-dispersion-model
   ```
5. **Open a Pull Request** with a detailed explanation of your changes and test coverage.

---

## 📜 License & Acknowledgments

- **License**: Distributed under the MIT License. See `LICENSE` for details.
- **Hackathon Context**: Developed for **HackMatrix 5.0** under the **Energy Track (Problem Statement: ENR-01 — Urban Environmental Digital Twin)**.
- **Data Acknowledgments**:
  - Central Pollution Control Board (CPCB), Government of India.
  - Rohan Rao for compiling and maintaining the Kaggle *Air Quality Data in India (2015–2020)* archive.
  - World Air Quality Index (WAQI) Project for open real-time air quality APIs.
  - Open-Meteo & OpenWeatherMap for open meteorological and wind vector APIs.

<div align="center">
<b>Atmos Twin</b> — Turning passive air data into active urban intelligence.
</div>
