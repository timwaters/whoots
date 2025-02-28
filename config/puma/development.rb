# Development configuration
environment 'development'
directory ENV.fetch('APP_ROOT', Dir.pwd)

# Development port
port ENV.fetch('PORT', 9292)

# Single worker for easier debugging
workers 1

# More threads for development to handle concurrent requests
threads 1, 6

# Enable code reloading
worker_timeout 3600 if ENV.fetch("RACK_ENV", "development") == "development"

# Development logging
quiet false

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart