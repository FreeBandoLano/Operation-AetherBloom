# AetherBloom Backend API

This is the backend API for the AetherBloom Smart Inhaler System. It provides endpoints for medication management, adherence tracking, and device simulation.

## Features

- **User Authentication**: Secure JWT-based authentication for patients and healthcare providers
- **Medication Management**: CRUD operations for medications, refill tracking, and adherence logging
- **Smart Inhaler Simulation**: Simulate BLE inhaler devices for development and testing
- **Analytics**: Calculate adherence statistics and usage patterns

## Setup

### Prerequisites

- Python 3.8 or newer
- PostgreSQL (optional, SQLite is used by default for development)

### Installation

1. Clone the repository
2. Navigate to the backend directory
3. Run the setup script:

```bash
# On Windows
run.bat

# On Linux/Mac
chmod +x run.sh
./run.sh
```

This will:
- Create a virtual environment
- Install dependencies
- Start the development server

### Manual Setup

If you prefer to set up manually:

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows
venv\Scripts\activate
# On Linux/Mac
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python server.py --reload
```

## API Documentation

Once the server is running, you can access the API documentation at:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Environment Variables

Create a `.env` file in the backend directory with the following variables:

```
SECRET_KEY=your_secret_key_here
DATABASE_URL=sqlite:///./aetherbloom.db  # Default SQLite database
# DATABASE_URL=postgresql://user:password@localhost/aetherbloom  # PostgreSQL
```

## Development

### Running Tests

```bash
pytest
```

### Database Migrations

The application uses SQLAlchemy models directly for development. For production, you should use Alembic migrations:

```bash
# Initialize Alembic (first time only)
alembic init alembic

# Create a migration
alembic revision --autogenerate -m "Initial migration"

# Apply migrations
alembic upgrade head
```

## Device Simulator

The backend includes a device simulator for testing without physical hardware:

1. Register a user (patient or doctor)
2. Use the `/api/simulator/start` endpoint to start a simulation
3. View simulated data in the `/api/simulator/events/{device_id}` endpoint

## License

This project is licensed under the MIT License - see the LICENSE file for details. 