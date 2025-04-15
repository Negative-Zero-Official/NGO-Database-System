from database import DatabaseManager
import sys

class NGOApp:
    def __init__(self):
        self.db = DatabaseManager()
        self.current_user = None

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
            
        self.db.execute_query(
            "INSERT INTO Adoptions (adopter_id, beneficiary_id, adoption_date) "
            "VALUES (%s, %s, CURDATE())",
            (self.current_user[0], beneficiary_id)
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

    def show_role_menu(self):
        role = self.get_user_role()
        {
            'Donor': self.donor_menu,
            'Adopter': self.adopter_menu,
            'Trustee': self.trustee_menu
        }.get(role, self.general_menu)()

    def donor_menu(self):
        while True:
            print("\nDonor Menu")
            print("1. Make Donation")
            print("2. View NGO Ratings")
            print("3. View NGO Reviews")
            print("4. View Upcoming Events")
            print("5. Submit Review")
            print("6. Logout")
            choice = input("Choose: ")
            if choice == '1': self.make_donation()
            elif choice == '2': self.view_ngo_ratings()
            elif choice == '3': self.view_ngo_reviews()
            elif choice == '4': self.view_upcoming_events()
            elif choice == '5': self.submit_review()
            elif choice == '6': 
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

    def trustee_menu(self):
        while True:
            print("\nTrustee Menu")
            print("1. Create Event")
            print("2. View Donation Summary")
            print("3. Submit Review")
            print("4. View NGO Ratings")
            print("5. View NGO Reviews")
            print("6. View Upcoming Events")
            print("7. Logout")
            choice = input("Choose: ")
            if choice == '1': self.create_event()
            elif choice == '2': self.view_donation_summary()
            elif choice == '3': self.submit_review()
            elif choice == '4': self.view_ngo_ratings()
            elif choice == '5': self.view_ngo_reviews()
            elif choice == '6': self.view_upcoming_events()
            elif choice == '7': 
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
        while True:
            if not self.current_user:
                choice = input("\nLogout successful. Exit program? (y/n): ").lower()
                if choice == 'y':
                    print("Exiting...")
                    sys.exit()
                self.login()
            else:
                self.show_role_menu()

if __name__ == "__main__":
    app = NGOApp()
    app.run()