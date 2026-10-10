# Asynchronous Worker REST API (Lyrics & Summary)

A simple, asynchronous worker REST API built with **AWS CDK (Python)** and designed to run seamlessly within **AWS CloudShell**. The API processes requests asynchronously, generating lyrics and summaries, and sends the results back to a specified endpoint.

## Features & Configuration
* **Asynchronous Architecture:** Uses AWS API Gateway and Lambda for non-blocking task processing.
* **OpenAI Integration:** Configured via the `OPENAI_API_KEY` environment variable.
* **Infrastructure as Code:** Built entirely with AWS CDK Python.

---

## Technical Analysis: AWS CloudShell Challenges & Solutions for Pluralsight Sandbox 

During development in the AWS CloudShell environment, several environment and deployment challenges were identified and resolved. Below is a summary of the fixes included in this repository:

### 1. AWS CloudShell Persistence
* **Challenge:** Global installations and system-level changes are lost after the CloudShell session ends.
* **Solution:** All project files, configurations, and dependencies are strictly managed within the `$HOME` directory to ensure persistence.

### 2. Python Dependencies (`ModuleNotFoundError`)
* **Challenge:** Required AWS CDK and project libraries are missing from the global Python environment.
* **Solution:** Always isolate dependencies. Activate the virtual environment and install the required packages before deploying:
  ```bash
  source .venv/bin/activate
  pip install -r requirements.txt
  ```

### 3. API Gateway Asynchronous Lambda Execution
* **Challenge:** Standard API Gateway proxy integrations invoke Lambda synchronously, causing the API to wait for the full execution response.
* **Solution:** Configured the integration with `proxy=False` and added the `X-Amz-Invocation-Type: 'Event'` header. This ensures API Gateway immediately responds with a `202 Accepted` status while Lambda processes the workload in the background.

### 4. AWS CDK: Python vs. TypeScript Differences
* **Challenge:** Syntax and argument structures differ between the TypeScript and Python CDK APIs, leading to runtime `TypeError` issues during synthesis.
* **Solution:** Rewrote and verified all infrastructure arguments to strictly comply with the Python CDK API reference.

### 5. CDK Versions & CLI Compatibility
* **Challenge:** Mismatches between the globally installed AWS CDK CLI and the project's library versions cause schema validation errors.
* **Solution:** Prefixed all CDK commands with `npx` (e.g., `npx aws-cdk synth`) to enforce local, version-locked CLI execution.

### 6. Missing CDK Bootstrap Resources
* **Challenge:** Deployments fail if the AWS account and region lack the required CDK staging resources.
* **Solution:** Run the bootstrap command once per AWS environment before the initial deployment:
  ```bash
  npx aws-cdk bootstrap
  ```

---

## Getting Started

1. **Make the deployment script executable:**
   ```bash
   chmod +x deploy.sh
   ```

2. **Deploy the stack:**
   ```bash
   ./deploy.sh
   ```
3. **Set up your Environment Variables:**
    Configure the OPENAI_API_KEY environment variable in your AWS Lambda function with your OpenAI API key.
 
