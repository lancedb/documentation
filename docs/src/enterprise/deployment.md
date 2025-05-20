---
title: "LanceDB Enterprise Deployment | Production Setup Guide"
description: "Learn how to deploy LanceDB Enterprise in production environments. Includes deployment options, configuration, and best practices for enterprise installations."
---

# Available Deployment Models

There are two deployment models available for LanceDB Enterprise: **Managed** and **BYOC**.
Both models support AWS, GCP, and Azure cloud platforms.

## Managed Deployment

**Managed deployment** is a private deployment of LanceDB Enterprise.
All applications run in cloud accounts managed by LanceDB in the same location as your client applications.

This hands-off approach is recommended for users who do not wish to manage the infrastructure themselves.

To access your deployment, LanceDB can provision either a public or private load balancer. 

## Bring Your Own Cloud (BYOC)

With this deployment model, LanceDB Enterprise is installed into your own cloud account.

This approach is recommended when:
- Users' security requirements for data residency preclude them from having data leave their account
- Other applications need to access the object storage directly

To deploy, an identity will be provisioned in your account with permissions to manage the infrastructure.

## Get Started

LanceDB Enterprise installation is highly configurable and customizable to your needs.
To get started, contact us at [contact@lancedb.com](mailto:contact@lancedb.com) for further instructions.
