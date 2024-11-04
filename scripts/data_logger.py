# scripts/data_logger.py

# Define a function to log data 
def log_data(data):
    # Open a file called "inhaler_data.txt" in append mode ("a" mode )
    with open("inhaler_data.txt","a") as file:
        # Write the data to the file, followed by a newline character
        file.write(f"{data}\n")
    print(f"Data logged: {data}")

# Test the log_data function
log_data("Test data: Dose 1 at 20:42")