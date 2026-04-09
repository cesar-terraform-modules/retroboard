I have a web app called "retroboard" that I need to deploy using StackGen.
My project is "cesar-retroboard-demo" on stage.dev.stackgen.com.

Our platform team already provisioned ECR repos in the "retroboard-registry" appstack. They also have a project called "cesar-demo-core-infra" which includes appstacks with core networking that we'll need to use for retroboard.

I need a single appstack called "retroboard" with everything my app and services need based on what you observe on this repository.

Create the appstack, configure everything, and apply it.
