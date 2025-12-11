#!/bin/bash

# Load environment variables from .env if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "Loaded environment variables from .env"
else
    echo "Warning: .env file not found. Email notifications will not work."
    echo "Copy .env.example to .env and configure your email settings."
fi

# Start the server
echo "Starting Dumb Idea app on http://0.0.0.0:9292"
rackup -o 0.0.0.0 -p 9292
