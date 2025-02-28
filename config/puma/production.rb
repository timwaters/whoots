# Production configuration for small server (128MB RAM)
environment 'production'
directory ENV.fetch('APP_ROOT', Dir.pwd)

# Production port
port ENV.fetch('PORT', 9292)

# Single worker for small server
workers 1

# Conservative thread count
threads 2, 4

# Quiet logging in production
quiet true

# Production timeouts
worker_timeout 60

# Memory optimization
max_heap_size = ENV.fetch('MAX_HEAP_SIZE', '64MB')
out_of_band_gc_count = ENV.fetch('OOB_GC_COUNT', 1)

before_fork do
  GC.compact if defined?(GC) && GC.respond_to?(:compact)
end

on_worker_boot do
  GC.start
end

# Memory monitoring
worker_check_interval 30
worker_timeout 30