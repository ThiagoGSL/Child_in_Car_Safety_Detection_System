import re

def convert_nrf_log_to_jpeg(log_file_path, output_jpeg_path):
    """
    Convert hexadecimal data from an nRF Connect log file to a JPEG image.
    
    Parameters:
    - log_file_path: Path to the nRF Connect log file (e.g., 'Log 2025-05-12 23_06_01.txt')
    - output_jpeg_path: Path for the output JPEG file (e.g., 'image.jpg')
    """
    # Initialize a list to store hex data for each image
    hex_data_list = []
    current_hex_data = ""

    # Regular expression to match hex values in the log
    # Matches lines like: "value: (0x) FF-D8-FF-E0-..."
    hex_pattern = r"value: \(0x\) ([\dA-F\-]+)"

    try:
        # Read the log file
        with open(log_file_path, 'r', encoding='utf-8') as file:
            for line in file:
                # Search for hex data in the line
                match = re.search(hex_pattern, line)
                if match:
                    # Extract the hex string (e.g., "FF-D8-FF-E0-...")
                    hex_chunk = match.group(1)
                    # Remove hyphens
                    hex_chunk = hex_chunk.replace("-", "")
                    # Check for JPEG start marker (FF D8)
                    if hex_chunk.startswith("FFD8") and current_hex_data:
                        # Save previous image data (if any) and start new image
                        hex_data_list.append(current_hex_data)
                        current_hex_data = hex_chunk
                    else:
                        # Append to current image data
                        current_hex_data += hex_chunk

            # Append the last image data (if any)
            if current_hex_data:
                hex_data_list.append(current_hex_data)

        if not hex_data_list:
            print("Error: No hexadecimal data found in the log file.")
            return

        # Process each image
        for i, hex_data in enumerate(hex_data_list):
            if not hex_data:
                continue

            # Convert hex string to binary data
            try:
                binary_data = bytes.fromhex(hex_data)
            except ValueError as e:
                print(f"Error: Invalid hex data for image {i+1} - {e}")
                continue

            # Write binary data to JPEG file
            output_file = f"{output_jpeg_path.rsplit('.', 1)[0]}_{i+1}.jpg"
            with open(output_file, 'wb') as jpeg_file:
                jpeg_file.write(binary_data)

            print(f"Success: JPEG image saved as '{output_file}'")
            print(f"Total bytes written for image {i+1}: {len(binary_data)}")

    except FileNotFoundError:
        print(f"Error: Log file '{log_file_path}' not found.")
    except Exception as e:
        print(f"Error: An unexpected error occurred - {e}")

# Example usage
if __name__ == "__main__":
    # Specify the input log file and output JPEG file
    log_file = r"C:\Users\tulio\Nova pasta - Copia\Downloads\Log 2025-05-13 10_13_22.txt"# Replace with your log file path
    output_jpeg = "image.jpg"  # Base name for output JPEG files

    convert_nrf_log_to_jpeg(log_file, output_jpeg)