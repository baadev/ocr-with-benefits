"""
Project Name: OCR based on Google services with some sweets
Author: Alexander Belov (baadev15@gmail.com)

  I know that can be confusing, especially setting up the project, so
  don't hesitate to contact me for any related questions


  This project is based on the Google Cloud Platform API,
    including: Cloud Document AI API and Cloud Translation API
    Don't forget to enable them in your project console

  Also you need to install some Python packages,
    including: google-api-core, google-cloud-translate etc
    use `pip3 install -r requirements.txt`

"""

import os
from typing import Optional
from fpdf import FPDF

from google.api_core.client_options import ClientOptions
from google.cloud import documentai
from google.cloud import translate_v3 as translate

# Set your project information
# 
# For more information, reference this page:
# https://cloud.google.com/document-ai/docs/setup
PROJECT_INFO = {
    'project_id': os.environ.get('PROJECT_ID'),
    'location': os.environ.get('LOCATION'),
    'processor_id': os.environ.get('PROCESSOR_ID'),
}

# You can translate output with Google Translations Service
#   btw, I don't recomend to do this if quality of input is poor
TRANSLATION_INFO = {
    'enabled': True if os.environ.get('TRANSLATION_CONSENT') == 'y' else False, 
    'location': 'global',
    'target_language_code': os.environ.get('TRANSLATION_TARGET_LANGUAGE'),
    # 'source_language_code': 'ru', # if not specified, source language will be detected automatically
}

# Paths to pdf files for OCR
PATHS = []
files_string = os.environ.get('FILES')
if files_string:
    PATHS = files_string.split(':')
else:
    print('No files specified.')
    raise SystemExit()

# Output file can be either 'txt' or 'pdf'
OUTPUT_FILE_FORMAT = os.environ.get('OUTPUT_FILE_FORMAT')



def extract_text(
    project_id: str,
    location: str,
    processor_id: str,
    file_path: str,
    mime_type: str,
    field_mask: Optional[str] = None,
    processor_version_id: Optional[str] = None,
) -> None:
    # You must set the `api_endpoint` if you use a location other than "us".
    opts = ClientOptions(api_endpoint=f"{location}-documentai.googleapis.com")

    client = documentai.DocumentProcessorServiceClient(client_options=opts)

    if processor_version_id:
        # The full resource name of the processor version, e.g.:
        # `projects/{project_id}/locations/{location}/processors/{processor_id}/processorVersions/{processor_version_id}`
        name = client.processor_version_path(
            project_id, location, processor_id, processor_version_id
        )
    else:
        # The full resource name of the processor, e.g.:
        # `projects/{project_id}/locations/{location}/processors/{processor_id}`
        name = client.processor_path(project_id, location, processor_id)

    # Read the file into memory
    with open(file_path, "rb") as image:
        image_content = image.read()

    # Load binary data
    raw_document = documentai.RawDocument(content=image_content, mime_type=mime_type)

    # Configure the process request
    request = documentai.ProcessRequest(
        name=name, raw_document=raw_document, field_mask=field_mask
    )

    result = client.process_document(request=request)

    # For a full list of `Document` object attributes, reference this page:
    # https://cloud.google.com/document-ai/docs/reference/rest/v1/Document
    document = result.document
    text = document.text
    return text


def translate_text(text: str):
    client = translate.TranslationServiceClient()

    parent = f"projects/{PROJECT_INFO['project_id']}/locations/{TRANSLATION_INFO['location']}"

    translated_text = ''

    # Split the texts into chunks of 1024, and translate each chunk separately
    for i in range(0, len(text), 1024):
        chunk = text[i:i+1024]

        response = client.translate_text(
            parent=parent,
            contents=chunk,
            target_language_code=TRANSLATION_INFO['target_language_code'],
            source_language_code=TRANSLATION_INFO['source_language_code']
        )

        # Add the translated texts from the response
        translated_text += "".join(translation.translated_text for translation in response.translations)

    return translated_text


def save_to_txt(text: str, file_path: str):
    # When you use multiple sources, FILE_SEPARATOR will be added to the end of the each file in .txt result 
    FILE_SEPARATOR = '## END OF THE FILE ##'

    with open(file_path, 'a', encoding='utf-8') as file:
        file.write(f'{text}\n{FILE_SEPARATOR}')

def save_to_pdf(text: str, file_path: str):
    pdf = FPDF()
    pdf.add_page()
    # Add a Unicode font
    pdf.add_font('DejaVu', '', 'DejaVuSansCondensed.ttf', uni=True)
    # Set the Unicode font
    pdf.set_font('DejaVu', '', 14)
    # Use multi_cell for text that may include line breaks
    pdf.multi_cell(0, 10, text)
    pdf.output(file_path)


# get text with Google DoOCR
def get_text_from_pdf(file_path):
    text = extract_text(
        project_id=PROJECT_INFO['project_id'],
        location=PROJECT_INFO['location'],
        processor_id=PROJECT_INFO['processor_id'],
        file_path=file_path,
        mime_type="application/pdf"
    )

    if (TRANSLATION_INFO['enabled'] == True): 
        text = translate_text(text)

    return text


if __name__ == '__main__':
    # Save to .txt file
    if (OUTPUT_FILE_FORMAT == 'txt'):
        for path in PATHS:
            text = get_text_from_pdf(path)
            save_to_txt(text, 'result.ocr.txt')

    # Save to .pdf file
    elif (OUTPUT_FILE_FORMAT == 'pdf'):
        text = ''
        for path in PATHS:
            text += f'{get_text_from_pdf(path)}\n'
        save_to_pdf(text, 'result.ocr.pdf')

    else:
        print(f'Unknown output mode{OUTPUT_FILE_FORMAT}')
        raise SystemExit()
