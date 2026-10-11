FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 DB_PATH=/data/alqoyyum.db
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app app
COPY seed seed
COPY tools tools
VOLUME /data
EXPOSE 8000
# Seed katalog dari Excel + akun Owner (hanya dibuat bila belum ada), lalu jalankan server.
CMD ["sh", "-c", "python -m app.seed && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
