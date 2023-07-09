FROM public.ecr.aws/lambda/python:3.9

# Install the function's dependencies using file requirements.txt
COPY requirements.txt  .
RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}

# Granting right to execute the function
RUN  chmod 755 app.py

# Set the CMD to the handler
CMD [ "app.visitors_count" ]

