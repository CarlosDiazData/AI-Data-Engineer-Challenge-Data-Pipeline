# AI + Data Engineer Challenge: Data Pipeline & KPI Analysis

This project is a comprehensive solution to the AI + Data Engineer technical challenge. It demonstrates an end-to-end process for data ingestion, warehousing, SQL modeling, and analysis, leveraging modern data tools like N8N for automation, Google BigQuery as a cloud data warehouse, and Python for analysis.

## Workflow & Architecture Overview

The solution is divided into two main stages, creating a clear and robust data flow:

1.  **Data Ingestion:** An N8N workflow, running in a Docker container, fetches a CSV dataset from a URL. It enriches the data with metadata (like load_date) and then loads the prepared data into a structured table in Google BigQuery.
    
2.  **KPI Analysis:** A local Python script connects securely to BigQuery. It executes a sophisticated SQL query to calculate key marketing KPIs (CAC and ROAS) and their performance deltas over time. The final results are printed to the console and saved as a structured JSON file.
    

![](https://raw.githubusercontent.com/CarlosDiazData/AI-Data-Engineer-Challenge-Data-Pipeline/refs/heads/main/docs/workflow.png)

## Tech Stack

-   **Automation & Orchestration:** N8N
    
-   **Containerization:** Docker, Docker Compose
    
-   **Data Warehouse:** Google BigQuery
    
-   **Analysis & Scripting:** Python, Pandas
    
-   **Database Language:** SQL
    

## Project Structure


```code
.
├── config/
│   └── gcp-credentials.json    # GCP service account key (add to .gitignore!)
├── exchange/
│   └── kpi_summary.json        # Output of the Python script.
├── n8n/
│   └── ingestion_workflow.json # Exported N8N workflow for import.
├── sql/
│   └── kpi_modeling.sql        # The main SQL query for KPI calculation.
├── .gitignore
├── docker-compose.yml          # Defines the N8N service.
├── README.md                   # This file.
└── run_analysis.py             # Python script to run the analysis.
```

## SQL Schema

The target table in BigQuery is created with a well-defined schema to ensure data types are correct for analysis.

### raw_ad_spend Table

This script must be run in the BigQuery UI to create the necessary table **before** running the N8N ingestion workflow.

```sql
-- Remember to replace `your-gcp-project-id` with your actual GCP Project ID.
CREATE OR REPLACE TABLE `your-gcp-project-id.ad_spend_data.raw_ad_spend` (
    date DATE,
    platform STRING,
    account STRING,
    campaign STRING,
    country STRING,
    device STRING,
    spend NUMERIC,
    clicks INTEGER,
    impressions INTEGER,
    conversions INTEGER,
    load_date TIMESTAMP,
    source_file_name STRING
);
```

## Setup & Installation

### Prerequisites

-   Git
    
-   Docker and Docker Compose
    
-   Python 3.8+ and Pip
    
-   A Google Cloud Platform (GCP) project with the BigQuery API enabled.
    

### 1. Google Cloud Setup

1.  **Create a Service Account:** In the GCP Console, navigate to IAM & Admin > Service Accounts. Create a new service account (e.g., n8n-writer).
    
2.  **Assign Roles:** Grant the service account the following two roles:
    
    -   BigQuery User (to run jobs)
        
    -   BigQuery Data Editor (to create and edit data)
        
3.  **Download JSON Key:** Create and download a JSON key for the service account.
    
4.  **Create BigQuery Resources:**
    
    -   Navigate to the BigQuery UI.
        
    -   First, create a new **dataset** named ad_spend_data.
        
    -   Then, open a query editor and run the CREATE TABLE script provided in the SQL Schema section above to create the raw_ad_spend table.
        

### 2. Local Setup

1.  **Clone the Repository:**
    
    codeBash
    
    ```
    git clone https://github.com/CarlosDiazData/AI-Data-Engineer-Challenge-Data-Pipeline.git
    cd AI-Data-Engineer-Challenge-Data-Pipeline
    ```
    
2.  **Place Credentials:**
    
    -   Create a folder named config.
        
    -   Place your downloaded GCP service account JSON key inside the config folder.
        
    -   **CRITICAL:** Ensure your .gitignore file contains config/ to prevent committing secrets to your repository.
        
3.  **Install Python Dependencies:**
    
   
    
    ```bash
    pip install google-cloud-bigquery pandas db-dtypes
    ```
    

## How to Run

The process is executed in two stages.

### Stage 1: Ingest Data with N8N

1.  **Start the N8N Service:**
    
    ```bash
    docker-compose up -d
    ```
    
2.  **Access N8N:** Open your browser and navigate to http://localhost:5678. Set up your owner account on the first run.
    
3.  **Import and Run Workflow:**
    
    -   Import the ingestion_workflow.json file from the n8n/ directory.
        
    -   Configure the BigQuery node with your GCP credentials (using the service account JSON key).
     
        
    -   Execute the workflow. This will populate the raw_ad_spend table in BigQuery.

![](https://raw.githubusercontent.com/CarlosDiazData/AI-Data-Engineer-Challenge-Data-Pipeline/refs/heads/main/docs/table.png)
        

### Stage 2: Run KPI Analysis

1.  **Execute the Python Script:**
    
  
    
    ```bash
    python run_analysis.py
    ```
    
2.  The script will connect to BigQuery, run the SQL query from sql/kpi_modeling.sql, print the final comparison table to your console, and save a kpi_summary.json file in the exchange/ folder.
    

## Results

Executing the analysis script produces the following KPI comparison table:


```code
metric  last_30_days  prior_30_days   delta
    CAC         39.63          45.21  -12.35%
   ROAS          3.36           3.02   11.51%
```

**Interpretation:** The results show a positive trend. The Cost to Acquire a Customer (CAC) has **decreased by 12.35%**, and the Return on Ad Spend (ROAS) has **increased by 11.51%**, indicating improved marketing efficiency and profitability.

## Part 4 – Bonus: AI Agent Demo

A natural-language question like “Compare CAC and ROAS for last 30 days vs prior 30 days.” can be answered by an AI agent using the output of this pipeline.

**1. Data Input:** The agent would receive the structured JSON output from our run_analysis.py script:

```json
[
    { "metric": "CAC", "last_30_days": 39.63, ... },
    { "metric": "ROAS", "last_30_days": 3.36, ... }
]
```

**2. Prompt:** This data would be passed to an LLM (like GPT or Gemini) with a system prompt instructing it to act as a marketing analyst.

**3. Generated Answer:** The AI would then produce a natural-language summary:

> "The analysis shows a significant improvement in advertising performance. The Cost to Acquire a Customer (CAC) has decreased by 12.35% to $39.63, while the Return on Ad Spend (ROAS) has increased by 11.51% to 3.36. This indicates a very positive trend in both efficiency and profitability."

This final step can be implemented directly in N8N by creating a second workflow that reads the kpi_summary.json file from the shared exchange/ folder and passes its content to an OpenAI or Google Gemini node.