FROM python:3.9

# Install the function's dependencies using file requirements.txt
COPY requirements.txt  .
RUN  pip3 install -r requirements.txt

# Copy function code
COPY app.py .

RUN  chmod 755 app.py

# Set the CMD to the handler
CMD ["python", "-c", "from app import visitors_count; visitors_count()"]

