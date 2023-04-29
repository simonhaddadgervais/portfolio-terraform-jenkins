# TERRAFORM

This Terraform configuration deploys my website infrastructure and was meant to replace my **SAM** configuration.

Terraform is way more complex and comprehensive than **SAM**, so it was not as easy as I thought, especially around
**ECR/Lambda** and **API Gateway**.

I split my tf main file into **backend** and **frontend**, with files for variables and providers, as the project is 
rather small and this segmentation is logical and convenient to me.

## Frontend

This part was the easiest, given how great the Terraform documentation is. I went through the **Terraform AWS
Registry** for each resource I needed : **S3**, **Cloudfront**, **Route53** and **ACM** and deployed successfully all the
resources without issues.

## Backend

This part was trickier. Deploying a **lambda function** as a **container image** was a first for me, and it got me really stuck
at some point.

Through the documentation I was able to deploy an **ECR repository** with a **Docker image** for my function, as well 
as an **API Gateway**. The API Gateway part requires a lot of resources, and it got me few tries to get `terraform apply` going through
without errors.

<br>

#### Image URI

However, the **lambda function** was not working properly with the **ECR image**. I manually tried some different
combinations on the **AWS Console** to find a setup that would make it work and I found out that the image referenced in
**Lambda** must contain the *SHA code* in order to work. My configuration was referencing it only with the tag in the end.

`image_uri     = "${aws_ecr_repository.repo.repository_url}:latest"`

So I create a reference data for my image :

```hcl
data "aws_ecr_image" "ecr_image" {
  repository_name = aws_ecr_repository.repo.name
  image_tag       = "latest"
}
```
        
And modified the `image_uri` accordingly in the `lambda_function` resource :

```hcl
image_uri     = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.ecr_image.id}"
```

This way **Lambda** was getting the image with the right information to ensures that the correct version of the container
image is used during the runtime of the lambda function.

<br>

#### ECR image availability
Then, `terraform apply` was getting stuck at recovering the *ecr_image* data. A second `terraform apply` would fix it, so 
I figured it was because the image needs a few moment before it is available for pulling. I simply added a `depends on`
in my `ecr_image` data to ensure that the image is available before Terraform attempts to create the lambda function
that depends on it.

```hcl
data "aws_ecr_image" "ecr_image" {
  depends_on      = [docker_registry_image.repo]
  repository_name = aws_ecr_repository.repo.name
  image_tag       = "latest"
}
```
<br>

#### Integration request type
But the API endpoint was not working. I kept getting hit with `{"message": "Internal server error"}`.

After a lot of troubleshooting I found the root cause.

I was using *LAMBDA PROXY* as the integration request type, but it turned out Lambda proxy integration is not supported with
Lambda functions that use container images. So I replaced `LAMBDA PROXY` with `AWS` in the type of integration in my
`api_gateway_integration` resource to have a *LAMBDA* integration type in my **API Gateway**.

<br>

#### Integration response

After fixing the integration request, the endpoint was working, but it was showing me the full JSON response from my
function. As I wanted only the body I needed to add a mapping template with some VTL code.

```
#set($inputRoot = $input.path('$'))
$inputRoot.body
```
I updated the `api_gateway_integration_response` resource with this code found on StackOverflow. It basically retrieves 
and store the full JSON payload into a variable and then extract the body from this variable.

```hcl
resource "aws_api_gateway_integration_response" "response" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # Extract body from the json response
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
EOF
  }
}
```

The issue was fixed! The output from the *API endpoint* was the JSON response body from my function :
`{"visitors": "272"}` !

<br>

#### CORS

The *API endpoint* was working successfully, unfortunately it couldn't be fetched by my script. The count was not showing
on my website (through the domain name and through the **Cloudfront** distribution). By inspecting the webpage and going to
the console I was able to retrieve the following error message :

`...has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.`

Therefor my next quest was to add *Access-Control-Allow-Origin* on my **API Gateway**.
To do that I imply added on my `integration_response` resource block:

`response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }`

and on my `method_response` resource block :

`response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }`

It was enough to fix the issue!






























