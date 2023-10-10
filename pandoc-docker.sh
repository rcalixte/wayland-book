#! /bin/sh

# Install dependencies for successful PDF generations
tlmgr install ctex enumitem float koma-script titling

# Generate PDFs using pandoc
for filename in pandoc-*yaml; do
  # Create variable for language based on filename
  language=`echo $filename | cut -d'.' -f1 | cut -d'-' -f2-3`

  # Attempt to create the PDF
  echo "Generating ${language} PDF..."
  pandoc -d ${filename}
  [[ $? -eq 0 ]] && echo "Success! The ${language} PDF has been successfully created!"
done
