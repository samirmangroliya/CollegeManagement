# College Management

Spring Boot application for college management with PostgreSQL and Docker-based deployment.

## Project overview

- Java 21
- Spring Boot 4
- PostgreSQL
- Docker
- GitHub Actions CI/CD
- AWS deployment via Amazon ECR and ECS

## Local development

### Prerequisites

- Java 21
- Maven or Maven Wrapper
- Docker and Docker Compose

### Run locally

```bash
./mvnw spring-boot:run
```

Or with Docker Compose:

```bash
docker compose up -d --build
```

### Environment files

Use the real local files for your machine:

- .env
- .env.dev
- .env.prod

Example files are safe to commit:

- .env.example
- .env.dev.example
- .env.prod.example

## AWS deployment

This project is configured for AWS deployment using:

- Amazon ECR for container image storage
- Amazon ECS for running the application
- GitHub Actions for CI/CD

### Required GitHub secrets

Add these repository secrets:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION

### Workflow

The deployment pipeline is in:

- .github/workflows/deploy-prod.yml

It builds the Docker image, pushes it to ECR, updates the ECS task definition, and deploys the new image to the ECS service.

## .azure folder

The .azure folder is not required for the application runtime or AWS deployment.

It is a local planning artifact created by tooling and is mainly used for project/containerization planning. It is not needed for Docker, ECS, or the Spring Boot app to run.

If you are not using it anymore, it can be deleted safely without affecting the application deployment.

## Docker build

```bash
docker build -t college-management:latest .
```

## Important notes

- Keep real environment files out of Git.
- Only commit example/template files.
- Do not commit .env, .env.dev, or .env.prod.

## Useful commands

```bash
# Build Docker image
docker build -t college-management:latest .

# Run with docker compose
docker compose up -d --build

# Check status
docker compose ps

# View logs
docker compose logs -f spring-boot-app
```
