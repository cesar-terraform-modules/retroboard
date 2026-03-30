# StackGen Demo Script -- Retroboard App

**Duration:** 20-30 minutes
**Persona:** Developer who vibecoded a retroboard app. Knows JavaScript/Python. Does NOT know AWS, Terraform, or infrastructure.
**Audience:** Potential StackGen customers (platform engineers, engineering leaders)

## Pre-Demo Setup

Run the setup script before the demo (see `scripts/demo-setup.sh`):

```bash
./scripts/demo-setup.sh
```

This pre-provisions everything the platform team would own:
- Core networking (VPC, subnets, NAT gateway) -- the slow resources
- ECR repositories + pre-built container images -- avoids Docker build during demo
- S3 state backend + DynamoDB lock table
- Cleans up leftover appstacks and stale state from previous runs

StackGen project, custom modules, security policies, and AWS credentials
are configured once in the UI and persist across demo runs.

**Also ensure:**
- Claude Code is open with the StackGen user MCP connected
- The retroboard source code is visible in the editor
- Docker is running (needed only for one frontend rebuild at the end)

---

## Act 1: The Narrative (2 min)

### Say to the Audience

> "I'm a developer. I built this retrospective board app -- it's a Next.js
> frontend with a Python FastAPI backend. I've been running it locally with
> Docker Compose. It works great on my laptop. Now I need to deploy it
> for real.
>
> I don't know Terraform. I don't know how cloud networking works. I don't
> even know what an 'IAM role' is. But my platform team told me I can use
> this AI assistant with StackGen to deploy my app. They said they've
> already set everything up -- I just need to describe what I have."

### Show on Screen

- Quick flash of the retroboard running locally (`make dev-up` or `docker compose up`)
- The project structure in the editor: `app/`, `functions/api/`, `functions/email-summary/`, `functions/notification-service/`

---

## Act 2: "Help Me Deploy This" (5 min)

### Prompt 1 -- The big ask

```
I have a web application called "retroboard" in this repo that I need to
deploy. Take a look at the code -- there's a frontend in app/, and backend
services in functions/. Each service has a Dockerfile. Check the
docker-compose.yml, the Dockerfiles, and the source code to understand
what the app needs.

My platform team gave me access to a StackGen project called
"cesar-retroboard-demo". Can you figure out what infrastructure I need
and help me set it up?
```

**What happens:** Claude will:
1. Read the codebase -- `docker-compose.yml`, Dockerfiles, `env.py`, `main.py` files
2. Discover ports, dependencies, and AWS service usage from the code itself
3. Use the StackGen MCP to list available modules
4. Propose an architecture mapping code-level needs to available modules
5. Suggest appstack organization

**Say to the audience:**

> "I didn't tell it what ports my services use, or what databases I need.
> I pointed it at my code. It read my Dockerfiles, my docker-compose,
> my Python imports -- and figured out that I need a NoSQL database, a
> message queue, an email service, and a load balancer. Then it checked
> what my platform team makes available through StackGen and mapped
> everything together."

### Prompt 2 -- Go ahead

```
That plan looks good. Go ahead and create the appstacks and add all the
resources. Use the dev environment.
```

**What happens:** Claude creates multiple appstacks and adds resources using the pre-approved modules. This triggers many parallel MCP calls.

**Say to the audience:**

> "Every resource it's adding comes from a module pre-approved by the
> platform team. The developer can't accidentally create an unencrypted
> S3 bucket or an overly permissive IAM role -- those options simply
> don't exist. This is governance by design, not by review."

---

## Act 3: Configuration (5 min)

### Prompt 3 -- Configure everything

```
Now configure all the resources. Look at the code again to figure out
the right ports, health checks, routing rules, and permissions each
service needs. The only things I know off the top of my head:

- The sender email is cesar@stackgen.com
- My platform team said to use environment-prefixed names so dev and
  prod don't collide
- The email-summary and notification services should be internal only
  (not public-facing)
```

**What happens:** Claude re-reads the source code to extract:
- Ports from Dockerfiles and `docker-compose.yml`
- API routes from FastAPI `main.py` (to set up ALB listener rules)
- AWS SDK usage from `env.py` and `repo.py` (to determine IAM permissions)
- Service discovery needs from how services reference each other
- Health check paths from the app code

Then it configures everything via `update_resource` calls.

**Say to the audience:**

> "I gave it two facts -- my email address and a naming convention.
> Everything else it figured out from reading the code. The ports came
> from the Dockerfiles. The routing rules came from the API endpoint
> definitions. The database permissions came from seeing DynamoDB
> imports in the Python code. This is why AI + StackGen is powerful --
> the AI understands code, and StackGen understands infrastructure."

---

## Act 4: "Am I Allowed to Deploy This?" (3 min)

### Prompt 4 -- Check policies

```
Before we deploy, can you check if my setup violates any security policies?
My platform team said they have guardrails in place.
```

**What happens:** Claude calls `get_current_violations` on each appstack. Expected: DynamoDB billing mode violation (MEDIUM) and possibly ALB HTTP/2 (LOW).

**Say to the audience (when violations appear):**

> "This is the governance layer. My platform team defined security policies
> in StackGen -- things like 'all DynamoDB tables must use provisioned
> billing' or 'all load balancers must enable HTTP/2'. The AI caught these
> BEFORE I tried to deploy, not after something breaks in production.
>
> For this demo, these are acceptable for a dev environment. In a real
> workflow, I'd either fix them or request a policy exception."

---

## Act 5: Deploy (5 min)

### Prompt 5 -- Deploy the infrastructure

```
Let's deploy! My platform team already created the container registries
and pushed the initial images, so I just need the infrastructure.
Set up the state backends, plan everything first, then apply.
```

**What happens:** Claude will:
1. Create environment profiles with S3 state backends
2. Run plans in dependency order (data + messaging first, compute last)
3. Apply each appstack
4. Monitor progress and report results

**Timing:** ~3-4 min total (images pre-built, ECR repos pre-created, NAT gateway already exists). Fill time with:
- The StackGen UI topology view (if available)
- The AWS console as resources appear
- Explaining the dependency order

**Say to the audience:**

> "The AI figured out the deployment order automatically. Data and
> messaging deploy first because the compute layer references them.
> Plans run before applies. Credentials are injected by StackGen's
> runner -- they never touch my laptop.
>
> Notice the container images are already in ECR -- our platform team
> pre-built those as part of onboarding. In a real workflow, your
> CI/CD pipeline pushes images and StackGen handles infrastructure."

### Prompt 6 -- Rebuild frontend with the real URL

```
The infrastructure is up but my frontend was built with a placeholder URL.
Can you rebuild just the frontend image with the correct load balancer
URL and redeploy it?
```

**What happens:** Claude finds the ALB DNS, rebuilds the app image with the correct `NEXT_PUBLIC_API_HOST_URL`, pushes it, and force-redeploys the ECS service. This is the one Docker command needed during the demo (~30s).

**Say to the audience:**

> "The only thing we need to rebuild is the frontend -- it bakes the
> API URL at build time. Everything else used the pre-built images.
> In production, your CI/CD pipeline handles this automatically."

---

## Act 6: The Payoff (3 min)

### Prompt 7 -- What's the URL?

```
Everything should be deployed now. What's the URL I can use to access my app?
```

**What happens:** Claude returns the ALB DNS name.

### Show on Screen

- Open the URL in a browser
- Create a new board with 3 sections
- Add sticky notes to each section
- Show the real-time UI working

**Say to the audience:**

> "There it is. A fully deployed, multi-service application. Four
> containers running on managed compute. A NoSQL database. Message
> queues. Email service. Load balancer with path-based routing.
> Internal service discovery. All deployed from natural language
> through an AI that was constrained by our platform team's policies
> and modules.
>
> The developer never wrote Terraform. Never configured a network.
> Never set up an IAM role. But everything follows the organization's
> standards because StackGen enforced them automatically."

---

## Act 7: "What If I Want Prod?" (2 min -- optional)

### Prompt 8 -- Deploy to prod

```
That's dev. How would I deploy the same thing to production with
bigger containers and more replicas?
```

**What happens:** Claude explains that the same appstack definitions work for prod -- just create prod environment profiles with different variable values (higher CPU/memory, more replicas). The environment namespacing means prod resources won't collide with dev.

**Say to the audience:**

> "Same infrastructure definition, different environment profile.
> That's the power of the pattern StackGen enforces -- environment
> isolation is built in from the start, not bolted on later."

---

## Closing (1 min)

> "Let me recap what just happened. A developer who doesn't know
> Terraform or AWS described their application in plain English.
> An AI assistant used StackGen's MCP to:
>
> - Discover pre-approved infrastructure modules
> - Create and configure all the resources
> - Enforce security policies before deployment
> - Deploy everything with proper state management
> - Use the organization's cloud credentials without exposing them
>
> The platform team stayed in control the whole time. They decided
> what modules exist, what policies apply, and what environments
> are available. The developer got self-service without sacrificing
> governance."

---

## Appendix A: Error Handling During Demo

| Error | What to Say | Fix |
|-------|-------------|-----|
| 422 from MCP | "Let me retry that with the right identifier" | Use UUID instead of name for `appstack_id` |
| Plan fails | "Looks like there's a configuration issue -- let me check the logs" | Use `get_action_run_logs` |
| Apply fails on permissions | "The platform team's IAM role needs an update -- this is a one-time setup issue" | Pre-fix IAM in setup script |
| Service discovery conflict | "There are still instances registered -- let me clean those up" | Deregister instances first |
| Slow apply | Show StackGen UI or AWS console while waiting | "This is the NAT gateway -- it takes a couple minutes" |

## Appendix B: Key Messages

| For Platform Engineers | For Engineering Leaders |
|----------------------|----------------------|
| You control the modules, policies, and environments | Developers ship faster without tickets to the platform team |
| Governance is enforced at deploy time, not review time | Same patterns work across teams and applications |
| MCP gives AI guardrails, not free rein | Credentials stay in the vault, not on laptops |
| Custom modules mean your standards, not generic defaults | Dev/prod isolation is structural, not a naming convention |
