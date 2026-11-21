"""Phase 1 check: verifies libraries are installed and MySQL is reachable."""
import mysql.connector
import numpy as np
import pandas as pd
import streamlit

from modules.db_connection import get_connection

print("Pandas   :", pd.__version__)
print("NumPy    :", np.__version__)
print("Streamlit:", streamlit.__version__)

try:
    connection = get_connection()
    if connection.is_connected():
        cursor = connection.cursor()
        cursor.execute("SELECT DATABASE();")
        print("Connected to MySQL database:", cursor.fetchone()[0])
        cursor.close()
        connection.close()
        print("\nSetup complete. Ready for Phase 2!")
except mysql.connector.Error as error:
    print("\nMySQL connection failed:", error)
    print("Check: MySQL is running, .env password is correct, database exists.")
