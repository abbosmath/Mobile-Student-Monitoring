web: python backend/manage.py migrate && gunicorn --changelog --cd backend config.wsgi:application --bind 0.0.0.0:$PORT
