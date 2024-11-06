# scripts/data_logger.py

from datetime import datetime # Import to work with timestamps

# Define a function to log data with timestamp and dose
def log_data(entry_type = "Dose", message = None):

    """
    Log data with a timestamp, entry type, and message or dose.
    Parameters:
    - entry_type (str): The type of entry, e.g, "Reminder", "Dose", "Event".
    - message (str): Optional custom message for the log
      """

    # Get the current timestamp
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # If the entry type is "Dose" and no message is provided, prompt user for the dose amount  
    if entry_type == "Dose" and message is None:
      print("choose dose amount: ")
      print("1. 1 puff")
      print("2. 2 puffs")
      while True:
            choice = input("Enter the number corresponding to your choice (1 or 2): ")
            if choice == "1":
                message = "1 puff"
                break
            elif choice == "2":
                message = "2 puffs"
                break
            else:
                print("Invalid choice. Please enter 1 or 2. ")
    # If no message is provided for other entry types, set a default message
    elif message is None: 
        message = "No additional information provided."

    # Open a file called 'inhaler_data.txt' in append mode ('a' mode)
    with open("inhaler_data.txt", "a") as file:
        # Write the timestamp and dose to the file, formatted nicely
        file.write(f"[{entry_type}]Timestamp: {timestamp}, Dose: {message}\n")

    # Print confirmation for debugging
    print(f"Data logged: [{entry_type}]Timestamp = {timestamp}, Dose = {message}")


# Test the log_data function
# log_data("Dose")    # Prompts the user for a dose amount 
# log_data("Reminder", "Take your inhaler!")  # Logs a reminder
# log_data("Event", "User checked inhaler status")    # Logs an event
