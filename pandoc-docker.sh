#! /bin/sh

# Install dependencies for successful PDF generations
tlmgr update --self
tlmgr install ctex enumitem float koma-script titling

# Generate PDFs using pandoc
for filename in pandoc-*yaml; do
  # Create variable for language based on filename
  language=$(echo "${filename}" | cut -d'.' -f1 | cut -d'-' -f2-3)

  # Attempt to create the PDF
  echo "Generating ${language} PDF..."
  if pandoc -d "${filename}"; then
    echo "Success! The ${language} PDF has been successfully created!"
  else
    echo "Failure! The ${language} PDF failed to be created!"
    exit 1
  fi
done
