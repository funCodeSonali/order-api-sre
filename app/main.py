from fastapi import FastAPI, HTTPException, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import random
import time

app = FastAPI()

APP_VERSION = "v2"

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status", "version"]
)

REQUEST_LATENCY = Histogram(
    "http_request_latency_seconds",
    "Request latency",
    ["endpoint", "version"]
)

@app.get("/health")
def health():
    return {"status": "ok", "version": APP_VERSION}

@app.post("/order")
def create_order():
    start_time = time.time()

    processing_time = random.uniform(0.1, 0.6)
    time.sleep(processing_time)

    if random.random() < 0.01:
        REQUEST_COUNT.labels(
            method="POST",
            endpoint="/order",
            status="500",
            version=APP_VERSION
        ).inc()

        REQUEST_LATENCY.labels(
            endpoint="/order",
            version=APP_VERSION
        ).observe(time.time() - start_time)

        raise HTTPException(status_code=500, detail="Order failed")

    REQUEST_COUNT.labels(
        method="POST",
        endpoint="/order",
        status="200",
        version=APP_VERSION
    ).inc()

    REQUEST_LATENCY.labels(
        endpoint="/order",
        version=APP_VERSION
    ).observe(time.time() - start_time)

    return {"result": "order created", "version": APP_VERSION}

@app.get("/metrics")
def metrics():
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )
