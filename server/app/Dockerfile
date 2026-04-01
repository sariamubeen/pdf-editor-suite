FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download pdf.js for PDF preview in signing page
RUN mkdir -p /app/static && \
    curl -sL -o /app/static/pdf.min.js https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js && \
    curl -sL -o /app/static/pdf.worker.min.js https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js

# Download handwriting fonts for type-to-signature
RUN mkdir -p /app/static/fonts && \
    curl -sL -o /app/static/fonts/Caveat.ttf "https://github.com/google/fonts/raw/main/ofl/caveat/Caveat%5Bwght%5D.ttf" && \
    curl -sL -o /app/static/fonts/DancingScript.ttf "https://github.com/google/fonts/raw/main/ofl/dancingscript/DancingScript%5Bwght%5D.ttf" && \
    curl -sL -o /app/static/fonts/GreatVibes.ttf "https://github.com/google/fonts/raw/main/ofl/greatvibes/GreatVibes-Regular.ttf"

COPY app.py .
COPY db.py .
COPY templates/ /app/templates/
COPY bundle/ /app/bundle/

RUN mkdir -p /app/uploads /app/signatures /app/data

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "120", "app:app"]
