from google.cloud import bigquery
from google.oauth2 import service_account
import pandas as pd
import os

# --- CONFIGURATION ---
# Define paths for credentials, SQL query, and the JSON output.
CREDENTIALS_PATH = os.path.join('config', 'bionic-genre-470500-t4-1700b057c135.json')
PROJECT_ID = "bionic-genre-470500-t4"
SQL_FILE_PATH = 'sql/kpi_modeling.sql'
OUTPUT_PATH = 'exchange/kpi_summary.json'

print("--- Running KPI analysis in BigQuery ---")

# --- EXECUTION ---
try:
    # Authenticate with Google Cloud using the explicit service account file.
    credentials = service_account.Credentials.from_service_account_file(CREDENTIALS_PATH)
    client = bigquery.Client(credentials=credentials, project=PROJECT_ID)

    # Read the entire SQL query from the .sql file.
    with open(SQL_FILE_PATH, 'r') as f:
        query = f.read()

    # Execute the query and load the results directly into a Pandas DataFrame.
    results_df = client.query(query).to_dataframe()

    # Save the resulting DataFrame to a JSON file in the shared 'exchange' folder.
    # The 'orient=records' format is ideal for API or further processing.
    results_df.to_json(OUTPUT_PATH, orient='records', indent=4)
    
    # Print the results to the console for immediate verification.
    print("\n---- Analysis Result ---")
    print(results_df.to_string(index=False))
    print(f"\n✅ Results saved successfully at: {OUTPUT_PATH}")

except Exception as e:
    print(f"An error occurred while running the query: {e}")