FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy only what the application needs, rather than the whole context, so
# nothing unexpected can end up inside the image.
COPY app.py .
COPY templates ./templates
COPY static ./static

# Run as a non-root user.
RUN useradd -m appuser
USER appuser

EXPOSE 8000
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]
