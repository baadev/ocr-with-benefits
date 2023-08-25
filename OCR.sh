#!/bin/sh

# Color codes for output styling
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Location of the configuration file
config_path='config.env'

# Banner
echo "${GREEN}----------------------------------------${NC}"
echo "${GREEN}  WELCOME TO THE AUTOMATED SETUP SCRIPT ${NC}"
echo "${GREEN}----------------------------------------${NC}\n"

# Install the required Python packages
echo "${GREEN}Installing Python packages...${NC}"
if pip3 install -r requirements.txt; then
  echo "${GREEN}Packages installed successfully!${NC}"
  echo ''
else
  echo "${RED}Failed to install packages. Exiting.${NC}"
  exit 1
fi


################################################################
# Project information
################################################################
ask_for_project_information()
{
  echo "Please enter project information"
  echo ""

  # Prompt for the path to the credentials file
  echo "Please enter the path to your Google credentials file"
  echo ""
  echo "For more information, please refer to the following link:"
  echo "https://cloud.google.com/docs/authentication/application-default-credentials"
  echo ""
  read -p "Path to credentials (or filename): " credentials_path
  # Check if the file exists
  if [ -f "$credentials_path" ]; then
    echo "Path to credentials set to: ${GREEN}$credentials_path${NC}"
  else
    echo "File not found: $file_path"
    exit 1
  fi
  echo ""

  echo "For more information, please refer to the following link:"
  echo "https://cloud.google.com/document-ai/docs/setup"
  echo ""

  read -p "Please enter the project_id: " project_id
  if [ -z "$project_id" ]; then
    echo "${RED}It's mandatory to set the project_id. Exiting.${NC}"
    exit 1
  fi
  echo "project_id set to: ${GREEN}$project_id${NC}"
  echo ""

  read -p "Please enter the location (default is 'eu'): " location
  if [ -z "$location" ]; then
    location="eu"
  fi
  echo "location set to: ${GREEN}$location${NC}"
  echo ""

  read -p "Please enter the processor_id: " processor_id
  if [ -z "$processor_id" ]; then
    echo "${RED}It's mandatory to set the processor_id. Exiting.${NC}"
    exit 1
  fi
  echo "processor_id set to: ${GREEN}$processor_id${NC}"
  echo ""

  # Ask if we need to save configs
  read -p "Do you want to save new configurations [Y/n]?" save_config
  save_config=$(echo $save_config | tr '[:upper:]' '[:lower:]')
  if [ -z "$save_config" ] || [ "$save_config" = "y"]; then

    # save variables
    echo "export GOOGLE_APPLICATION_CREDENTIALS=$credentials_path" > "$config_path"
    echo "export PROJECT_ID=$project_id" >> "$config_path"
    echo "export LOCATION=$location" >> "$config_path"
    echo "export PROCESSOR_ID=$processor_id" >> "$config_path"


    echo "${GREEN}Configuration saved${NC}"
    echo ""
  fi

  # Exporting the variables so they can be accessed Python program
  export GOOGLE_APPLICATION_CREDENTIALS=$credentials_path
  export PROJECT_ID=$project_id
  export LOCATION=$location
  export PROCESSOR_ID=$processor_id
}

if [ -f "$config_path" ]; then
  # Ask if we need to load saved configs
  read -p "Do you want to use previously saved configurations [Y/n]?" use_previous_config
  use_previous_config=$(echo $use_previous_config | tr '[:upper:]' '[:lower:]')
  if [ -z "$use_previous_config" ] || [ "$use_previous_config" = "y"]; then
    # Load saved configuration
    source "$config_path"

    echo "${GREEN}Configuration loaded${NC}"

    echo "GOOGLE_APPLICATION_CREDENTIALS: ${GREEN}$GOOGLE_APPLICATION_CREDENTIALS${NC}"
    echo "PROJECT_ID: ${GREEN}$PROJECT_ID${NC}"
    echo "LOCATION: ${GREEN}$LOCATION${NC}"
    echo "PROCESSOR_ID: ${GREEN}$PROCESSOR_ID${NC}"
    echo ""
  else 
    ask_for_project_information
  fi
else
  ask_for_project_information
fi


################################################################
# Translations
################################################################
read -p "Do you want translate the output [y/N]?" translation_consent
# Convert to lowercase to accept 'y' or 'Y'
translation_consent=$(echo $translation_consent | tr '[:upper:]' '[:lower:]')
if [ "$translation_consent" = "y" ]; then
  read -p "Translation target language code (default: 'en'): " $translation_target_language
  if [ -z "$translation_target_language" ]; then
    translation_target_language="en"
  fi
  echo "translation target language set to: ${GREEN}$translation_target_language${NC}"
fi


################################################################
# Input
################################################################
echo "Please specify the PDF files you want to parse. Leave blank ('') when finished."
files=() # Array to hold file paths

# Ask for as many files we need
while true; do
  read -p "Enter the path to a PDF file or leave it blank to finish: " file_path
  if [ -z "$file_path" ]; then
    break
  fi

  # Check if the file exists
  if [ -f "$file_path" ]; then
    files+=("$file_path") # Add file path to the array
    echo "Added: ${GREEN}$file_path${NC}"
  else
    echo "File not found: $file_path"
  fi
done


################################################################
# Output
################################################################

while true; do
  read -p "Please choose the output file format ('txt' or 'pdf', default 'txt'): " output_file_format
  if [ -z "$output_file_format" ]; then
    output_file_format="txt"
  fi

  case "$output_file_format" in
    txt|pdf)
      echo "output_file_format set to: ${GREEN}$output_file_format${NC}"
      break
      ;;
    *)
      echo "Invalid choice. Please enter 'txt' or 'pdf'."
      ;;
  esac
done


# Exporting the variables so they can be accessed Python program
export TRANSLATION_CONSENT=$translation_consent
export TRANSLATION_TARGET_LANGUAGE=$translation_target_language

export FILES=$(IFS=":"; echo "${files[*]}")

export OUTPUT_FILE_FORMAT=$output_file_format


# Call OCR Python script
echo "${GREEN}Executing OCR script...${NC}"
python3 main.py
if [ $? -eq 0 ]; then
  echo "${GREEN}SUCCESS${NC}"
else
  echo "${RED}FAILED${NC}"
fi
