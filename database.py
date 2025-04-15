import mysql.connector
from mysql.connector import Error
from config import DB_CONFIG

class DatabaseManager:
    def __init__(self):
        self.connection = None
        self.connect()

    def connect(self):
        try:
            self.connection = mysql.connector.connect(**DB_CONFIG)
        except Error as e:
            print(f"Error connecting to the database: {e}")
            self.connection = None

    def execute_query(self, query, params=None, fetch=False):
        if not self.connection or not self.connection.is_connected():
            self.connect()  # Reconnect if the connection is lost
        if not self.connection:
            print("Failed to reconnect to the database.")
            return None

        cursor = self.connection.cursor()
        try:
            cursor.execute(query, params or ())
            if fetch:
                return cursor.fetchall()
            self.connection.commit()
        except Error as e:
            print(f"Database error: {e}")
        finally:
            cursor.close()