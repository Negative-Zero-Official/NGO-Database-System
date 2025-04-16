from database import DatabaseManager
import sys

class NGOApp:
    def __init__(self):
        self.db = DatabaseManager()
        self.current_user = None
        self.table_columns = {
            'Users': ['user_id', 'username', 'email', 'password_hash', 'created_at'],
            'Locations': ['location_id', 'city', 'state', 'country', 'latitude', 'longitude'],
            'NGOs': ['ngo_id', 'name', 'description', 'website', 'contact_email', 
                     'contact_phone', 'location_id', 'created_at'],
            'NGO_Categories': ['ngo_id', 'category_id', 'category_name'],
            'Donors': ['donor_id', 'user_id', 'name', 'email', 'phone', 'donor_type', 'created_at'],
            'Donations': ['donation_id', 'user_id', 'ngo_id', 'donor_id', 'amount', 
                         'donation_date', 'payment_method'],
            'Beneficiaries': ['beneficiary_id', 'name', 'age', 'gender', 'ngo_id', 'received_support'],
            'Adopters': ['adopter_id', 'user_id', 'name', 'email', 'phone', 'address'],
            'Adoptions': ['adoption_id', 'adopter_id', 'beneficiary_id', 'adoption_date'],
            'Trustees': ['trustee_id', 'user_id', 'name', 'email', 'phone', 'position', 'ngo_id'],
            'Events': ['event_id', 'name', 'description', 'ngo_id', 'event_date', 'location'],
            'Reviews': ['review_id', 'user_id', 'ngo_id', 'rating', 'review_text', 'created_at']
        }

    def login(self):
        username = input("Username: ")
        password = input("Password: ")
        
        result = self.db.execute_query(
            "CALL AuthenticateUser(%s, %s)", 
            (username, password),
            fetch=True
        )
        
        if result:
            self.current_user = result[0]
            print(f"Welcome {self.current_user[1]}!")
            self.show_role_menu()
        else:
            print("Invalid credentials!")

    def make_donation(self):
        self.list_ngos()
        ngo_id = int(input("Enter NGO ID: "))
        amount = float(input("Amount: "))
        method = input("Payment method (Credit Card/PayPal/Bank Transfer): ")
        
        self.db.execute_query(
            "INSERT INTO Donations (user_id, ngo_id, amount, payment_method) "
            "VALUES (%s, %s, %s, %s)",
            (self.current_user[0], ngo_id, amount, method)
        )
        print("Donation recorded!")

    def view_available_beneficiaries(self):
        beneficiaries = self.db.execute_query(
            "SELECT * FROM Available_Beneficiaries_View", fetch=True
        )
        for b in beneficiaries:
            print(f"{b[0]}: {b[1]} ({b[2]} years old)")

    def adopt_beneficiary(self):
        self.view_available_beneficiaries()
        beneficiary_id = int(input("Enter Beneficiary ID: "))

        conflict = self.db.execute_query(
            "SELECT CheckAdoptionConflict(%s)", (beneficiary_id,), fetch=True
        )[0][0]

        if conflict:
            print("Already adopted!")
            return

        # Fetch adopter_id using current user's user_id
        result = self.db.execute_query(
            "SELECT adopter_id FROM Adopters WHERE user_id = %s",
            (self.current_user[0],),
            fetch=True
        )
        if not result:
            print("You are not registered as an adopter.")
            return

        adopter_id = result[0][0]

        self.db.execute_query(
            "INSERT INTO Adoptions (adopter_id, beneficiary_id, adoption_date) "
            "VALUES (%s, %s, CURDATE())",
            (adopter_id, beneficiary_id)
        )
        print("Adoption successful!")


    def get_trustee_ngo(self):
        result = self.db.execute_query(
            "SELECT ngo_id FROM Trustees WHERE user_id = %s",
            (self.current_user[0],),
            fetch=True
        )
        return result[0][0] if result else None

    def create_event(self):
        name = input("Event name: ")
        desc = input("Description: ")
        date = input("Date (YYYY-MM-DD): ")
        location = input("Location: ")
        
        self.db.execute_query(
            "CALL CreateEvent(%s, %s, %s, %s, %s)",
            (name, desc, self.get_trustee_ngo(), date, location)
        )
        print("Event created!")

    def view_donation_summary(self):
        ngo_id = self.get_trustee_ngo()
        summary = self.db.execute_query(
            "SELECT * FROM Donation_Summary_View WHERE ngo_id = %s",
            (ngo_id,),
            fetch=True
        )
        if summary:
            data = summary[0]
            print(f"\nNGO: {data[1]}")
            print(f"Total Donations: ${data[2]:.2f} ({data[3]} donations)")

    def submit_review(self):
        self.list_ngos()
        ngo_id = int(input("NGO ID: "))
        rating = int(input("Rating (1-5: "))
        text = input("Review text: ")
        
        try:
            self.db.execute_query(
                "CALL SubmitReview(%s, %s, %s, %s)",
                (self.current_user[0], ngo_id, rating, text)
            )
            print("Review submitted!")
        except Exception as e:
            print(f"Error: {e}")

    def view_ngo_ratings(self):
        ratings = self.db.execute_query(
            "SELECT * FROM NGO_Ratings_View", fetch=True
        )
        for r in ratings:
            print(f"{r[1]}: {r[2]:.1f} stars ({r[3]} reviews)")

    def view_ngo_reviews(self):
        self.list_ngos()
        ngo_id = int(input("Enter NGO ID to view reviews: "))
        reviews = self.db.execute_query(
            "SELECT rating, review_text, created_at FROM Reviews WHERE ngo_id = %s",
            (ngo_id,),
            fetch=True
        )
        if not reviews:
            print("No reviews yet.")
            return
        for idx, (rating, text, date) in enumerate(reviews, 1):
            print(f"\nReview {idx}:")
            print(f"Rating: {rating}/5")
            print(f"Date: {date}")
            print(f"Text: {text}")

    def view_upcoming_events(self):
        events = self.db.execute_query(
            "SELECT * FROM Upcoming_Events_View", 
            fetch=True
        )
        if not events:
            print("No upcoming events.")
            return
        for event in events:
            print(f"\nEvent: {event[1]}")
            print(f"Date: {event[4]}")
            print(f"Location: {event[5]}")
            print(f"Description: {event[2]}")

    def list_ngos(self):
        ngos = self.db.execute_query("SELECT * FROM NGOs", fetch=True)
        for n in ngos:
            print(f"{n[0]}: {n[1]}")

    def get_user_role(self):
        return self.db.execute_query(
            "SELECT GetUserRole(%s)", (self.current_user[0],), fetch=True
        )[0][0]

    def add_ngo(self):
        print("\nAdd New NGO")
        name = input("Name: ")
        desc = input("Description: ")
        website = input("Website: ")
        email = input("Contact Email: ")
        phone = input("Contact Phone: ")
        city = input("City: ")
        state = input("State: ")
        country = input("Country: ")
        lat = float(input("Latitude: "))
        lng = float(input("Longitude: "))
        
        self.db.execute_query(
            "CALL AddNGO(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (name, desc, website, email, phone, city, state, country, lat, lng)
        )
        print("NGO added successfully!")

    def update_ngo(self):
        self.list_ngos()
        ngo_id = int(input("Enter NGO ID to update: "))
        name = input("New Name (leave blank to keep current): ")
        desc = input("New Description (leave blank to keep current): ")
        website = input("New Website (leave blank to keep current): ")
        email = input("New Email (leave blank to keep current): ")
        phone = input("New Phone (leave blank to keep current): ")
        
        # Fetch current values if fields are blank
        current = self.db.execute_query(
            "SELECT name, description, website, contact_email, contact_phone FROM NGOs WHERE ngo_id = %s",
            (ngo_id,),
            fetch=True
        )[0]
        
        name = name or current[0]
        desc = desc or current[1]
        website = website or current[2]
        email = email or current[3]
        phone = phone or current[4]
        
        self.db.execute_query(
            "CALL UpdateNGO(%s, %s, %s, %s, %s, %s)",
            (ngo_id, name, desc, website, email, phone)
        )
        print("NGO updated!")

    def delete_ngo(self):
        self.list_ngos()
        ngo_id = int(input("Enter NGO ID to delete: "))
        confirm = input(f"WARNING: This will permanently delete NGO {ngo_id}. Confirm? (y/n): ")
        if confirm.lower() == 'y':
            self.db.execute_query("CALL DeleteNGO(%s)", (ngo_id,))
            print("NGO deleted.")
        else:
            print("Deletion canceled.")

    def view_table_details(self):
        tables = [
            'Users', 'NGOs', 'Locations', 'Donors',
            'Donations', 'Beneficiaries', 'Adopters',
            'Adoptions', 'Trustees', 'Events', 'Reviews',
            'NGO_Categories'
        ]
        print("\nAvailable Tables:")
        for idx, table in enumerate(tables, 1):
            print(f"{idx}. {table}")
        
        try:
            choice = int(input("Select table (number): "))
            table_name = tables[choice-1]
        except (ValueError, IndexError):
            print("Invalid selection!")
            return
        
        try:
            data = self.db.execute_query(
                "CALL AdminGetTableData(%s)",
                (table_name,),
                fetch=True
            )
            if not data:
                print(f"\n{table_name} table is empty.")
                return
                
            print(f"\n{table_name} Table Data:")
            for row in data:
                print("\n" + "-"*40)
                for idx, value in enumerate(row):
                    print(f"{self.table_columns[table_name][idx]}: {value}")
        except Exception as e:
            print(f"Error: {e}")

    # ----- Updated Admin Menu -----
    def admin_menu(self):
        while True:
            print("\nAdmin Menu")
            print("1. Add NGO")
            print("2. Update NGO")
            print("3. Delete NGO")
            print("4. View NGO Ratings")
            print("5. View NGO Reviews")
            print("6. View Upcoming Events")
            print("7. Submit Review")
            print("8. View Table Details")  # New option
            print("9. Logout")
            choice = input("Choose: ")
            if choice == '1': 
                self.add_ngo()
            elif choice == '2': 
                self.update_ngo()
            elif choice == '3': 
                self.delete_ngo()
            elif choice == '4': 
                self.view_ngo_ratings()  # Inherited from general features
            elif choice == '5': 
                self.view_ngo_reviews()  # Inherited from general features
            elif choice == '6': 
                self.view_upcoming_events()  # Inherited from general features
            elif choice == '7': 
                self.submit_review()  # Inherited from general features
            elif choice == '8':
                self.view_table_details()
            elif choice == '9':
                self.current_user = None
                return
            else: 
                print("Invalid choice!")

    def show_role_menu(self):
        role = self.get_user_role()
        {
            'Donor': self.donor_menu,
            'Adopter': self.adopter_menu,
            'Trustee': self.trustee_menu,
            'Admin': self.admin_menu
        }.get(role, self.general_menu)()

    def search_ngos_by_location(self):
        print("\nSearch NGOs by Location")
        print("1. Search by City")
        print("2. Search by State") 
        print("3. Search by Country")
        choice = input("Choose search type (1-3): ")

        search_types = {1: 'city', 2: 'state', 3: 'country'}
        search_type = search_types.get(int(choice), None)
        
        if not search_type:
            print("Invalid choice!")
            return

        search_term = input(f"Enter {search_type} name: ")
        
        results = self.db.execute_query(
            "CALL SearchNGOsByLocation(%s, %s)",
            (search_type, search_term),
            fetch=True
        )

        if not results:
            print("\nNo NGOs found in this location.")
            return

        print("\nSearch Results:")
        for ngo in results:
            print(f"\nID: {ngo[0]}")
            print(f"Name: {ngo[1]}")
            print(f"Description: {ngo[2]}")
            print(f"Location: {ngo[3]}, {ngo[4]}, {ngo[5]}")

    def donor_menu(self):
        while True:
            print("\nDonor Menu")
            print("1. Make Donation")
            print("2. View NGO Ratings")
            print("3. View NGO Reviews")
            print("4. View Upcoming Events")
            print("5. Submit Review")
            print("6. Search NGOs by Location")  # New option
            print("7. Logout")
            choice = input("Choose: ")
            if choice == '1': self.make_donation()
            elif choice == '2': self.view_ngo_ratings()
            elif choice == '3': self.view_ngo_reviews()
            elif choice == '4': self.view_upcoming_events()
            elif choice == '5': self.submit_review()
            elif choice == '6': self.search_ngos_by_location()  # New feature
            elif choice == '7': 
                self.current_user = None
                return
            else: print("Invalid choice!")

    def adopter_menu(self):
        while True:
            print("\nAdopter Menu")
            print("1. View Available Beneficiaries")
            print("2. Adopt a Beneficiary")
            print("3. Submit Review")
            print("4. View NGO Ratings")
            print("5. View NGO Reviews")
            print("6. View Upcoming Events")
            print("7. Logout")
            choice = input("Choose: ")
            if choice == '1': self.view_available_beneficiaries()
            elif choice == '2': self.adopt_beneficiary()
            elif choice == '3': self.submit_review()
            elif choice == '4': self.view_ngo_ratings()
            elif choice == '5': self.view_ngo_reviews()
            elif choice == '6': self.view_upcoming_events()
            elif choice == '7': 
                self.current_user = None
                return
            else: print("Invalid choice!")

    def view_trustee_beneficiaries(self):
        beneficiaries = self.db.execute_query(
            "CALL GetTrusteeBeneficiaries(%s)",
            (self.current_user[0],),
            fetch=True
        )
        if not beneficiaries:
            print("No beneficiaries under your NGO.")
            return
        print("\nBeneficiaries under your NGO:")
        for b in beneficiaries:
            print(f"ID: {b[0]}, Name: {b[1]}, Age: {b[2]}, Gender: {b[3]}")
            print(f"Support Received: {b[5]}\n")

    # ----- Updated Trustee Menu -----
    def trustee_menu(self):
        while True:
            print("\nTrustee Menu")
            print("1. Create Event")
            print("2. View Donation Summary")
            print("3. Submit Review")
            print("4. View NGO Ratings")
            print("5. View NGO Reviews")
            print("6. View Upcoming Events")
            print("7. View Beneficiaries")  # New option
            print("8. Logout")
            choice = input("Choose: ")
            if choice == '1': self.create_event()
            elif choice == '2': self.view_donation_summary()
            elif choice == '3': self.submit_review()
            elif choice == '4': self.view_ngo_ratings()
            elif choice == '5': self.view_ngo_reviews()
            elif choice == '6': self.view_upcoming_events()
            elif choice == '7': self.view_trustee_beneficiaries()  # Call new method
            elif choice == '8': 
                self.current_user = None
                return
            else: print("Invalid choice!")

    def general_menu(self):
        while True:
            print("\nGeneral User Menu")
            print("1. View NGO Ratings")
            print("2. View NGO Reviews")
            print("3. View Upcoming Events")
            print("4. Exit")
            choice = input("Choose: ")
            if choice == '1': self.view_ngo_ratings()
            elif choice == '2': self.view_ngo_reviews()
            elif choice == '3': self.view_upcoming_events()
            elif choice == '4': sys.exit()
            else: print("Invalid choice!")

    def run(self):
        first_run = True  # Flag to track the first run
        while True:
            if not self.current_user:
                if not first_run:
                    print("\nLogout successful.")
                    choice = input("Exit program? (y/n): ").lower()
                    if choice == 'y':
                        print("Exiting...")
                        sys.exit()
                first_run = False  # Set to False after the first iteration
                self.login()
            else:
                self.show_role_menu()

if __name__ == "__main__":
    app = NGOApp()
    app.run()