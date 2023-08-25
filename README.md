# ocr-with-benefits
OCR based on Google services with some sweets

## Feautures
* OCR with *Google Cloud Document AI*
* Translation of output with *Google Cloud Translation*
* Multiple input files
* Different output formats (currently: .txt and .pdf)

## Setup
ocr-with-benefits is based on the Google Cloud Platform API, so you need to do some steps in your [GCP Console](https://cloud.google.com/document-ai/docs/setup#gcp-console).
1. [Create a GCP project](https://cloud.google.com/document-ai/docs/setup#project)
2. Enable API: [*Document AI*](https://cloud.google.com/document-ai/docs/setup#api) and [*Translation*](https://cloud.google.com/translate/docs/setup#api)
3. [Create a service account and download the private key file](https://cloud.google.com/document-ai/docs/setup#sa-create). 

### To start the program run
```sh
sh OCR.sh 
```
you will be prompted for additional information

### Notes
I know that can be confusing, especially setting up the project in GCP, so
don't hesitate to [contact me](mailto:baadev15@gmail.com) for any related questions
