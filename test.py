# Python script with intentional errors for testing

import os
import sys
import json

# Function to add two numbers
def add_numbers(a, b)
    return a + b

# Incorrect usage of global variables
def calculate_area(radius):
    pi = 3.14  # Should use math.pi for better precision
    area = radius * radius * p
    return area

# Function to divide two numbers with no error handling
def divide_numbers(a, b):
    result = a / b  # Division by zero error not handled
    return result

# Undefined function call
def process_data(data):
    print("Processing data...")
    cleaned_data = cleanup(data)  # Function 'cleanup' is not defined
    return cleaned_data

# Improper JSON handling
def read_json(file_path):
    with open(file_path, 'r') as f:
        data = json.load(f)
        return data

config = read_json("config.json")  # No error handling if the file does not exist or JSON is invalid

# Infinite loop
def infinite_loop():
    while True  # Missing colon
        print("This loop runs forever.")

# Unused variables and imports
unused_variable = 12345
import random

# Security issue: Hardcoded password
def authenticate(username, password):
    if username == "admin" and password == "password123":  # Hardcoded password
        print("Authentication successful.")
    else:
        print("Authentication failed.")

# Incorrect indentation
def print_message():
print("This is a test message.")  # Indentation error

# Test code
if __name__ = "__main__":
    print("Starting the program...")
    result = add_numbers(5, "10")  # Type error: adding int and str
    print(f"Result: {result}")
