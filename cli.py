import mysql.connector
from mysql.connector import Error

host = ""
user = ""
password = ""
database = ""

def get_dbs_info():
    global host, user, password, database
    host = input("Enter host: ")
    user = input("Enter user: ")
    password = input("Enter password: ")
    database = input("Enter database name: ")

# Database connection
def connect_to_db():
    try:
        connection = mysql.connector.connect(
            host = host,
            user = user,
            password = password,
            database = database
        )
        return connection
    except Error as e:
        print(f"Error connecting to database: {e}")
        return None

# Function to check if a username exists
def check_username_exists(username):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT user_id FROM users WHERE username = %s", (username,))
        result = cursor.fetchone()
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# Function to check if an email exists
def check_email_exists(email):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fn_email_exists(%s)", (email,))
        result = cursor.fetchone()[0]
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# Function to validate password strength
def validate_password(password):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fn_validate_password(%s)", (password,))
        result = cursor.fetchone()[0]
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# Function to get user role
def get_user_role(user_id):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fn_get_user_role(%s)", (user_id,))
        result = cursor.fetchone()[0]
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# Function to get total donations by a user
def get_user_total_donations(user_id):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fn_get_user_total_donations(%s)", (user_id,))
        result = cursor.fetchone()[0]
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# Function to get total donations to an NGO
def get_ngo_total_donations(ngo_id):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fn_get_ngo_total_donations(%s)", (ngo_id,))
        result = cursor.fetchone()[0]
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# Function to get NGO average rating
def get_ngo_avg_rating(ngo_id):
    try:
        conn = connect_to_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fn_get_ngo_avg_rating(%s)", (ngo_id,))
        result = cursor.fetchone()[0]
        return result
    except Error as e:
        print(f"Error: {e}")
    finally:
        conn.close()

# CLI Menu
def main():
    while True:
        print("\nNGO Search Engine CLI")
        print("1. Check if username exists")
        print("2. Check if email exists")
        print("3. Validate password strength")
        print("4. Get user role")
        print("5. Get total donations by a user")
        print("6. Get total donations to an NGO")
        print("7. Get NGO average rating")
        print("0. Exit")
        
        choice = int(input("Enter your choice: "))
        match choice:
            case 1:
                username = input("Enter username: ")
                exists = check_username_exists(username)
                if exists:
                    print(f"Username exists: {exists[0]}")
                else:
                    print("User not found")
            case 2:
                email = input("Enter email: ")
                exists = check_email_exists(email)
                print(f"Email exists: {exists}")
            case 3:
                password = input("Enter password: ")
                valid = validate_password(password)
                print(f"Password valid: {valid}")
            case 4:
                user_id = int(input("Enter user ID: "))
                role = get_user_role(user_id)
                print(f"User role: {role}")
            case 5:
                user_id = int(input("Enter user ID: "))
                total_donations = get_user_total_donations(user_id)
                print(f"Total donations by user: {total_donations}")
            case 6:
                ngo_id = int(input("Enter NGO ID: "))
                total_donations = get_ngo_total_donations(ngo_id)
                print(f"Total donations to NGO: {total_donations}")
            case 7:
                ngo_id = int(input("Enter NGO ID: "))
                avg_rating = get_ngo_avg_rating(ngo_id)
                print(f"NGO average rating: {avg_rating}")
            case 0:
                print("Exiting...")
                break
            case _:
                print("Invalid choice. Please try again.")

if __name__ == "__main__":
    get_dbs_info()
    main()