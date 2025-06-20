# Deployment and configuration for Geneva

Geneva is a client-side library that simplifies feature engineering at scale.  To handle multimodal distributed processing, Geneva uses Ray, a distributed processing system.  Geneva can use Ray deployed locally on your laptop, against an existing Ray cluster, or provision Ray on demand on a kubernetes cluster using the kuberay operator.  

This page will help cloud admins understand and setup Geneva's requirements.

# Geneva on Kubernetes deployments

Prerequisites

* Kubernetes cluster with kuberay 1.1+ operator installed.
* Ray 2.43+ 

## Geneva on GKE

Google Kubernetes Engine (GKE) is a GCP service that deploys Kubernetes and can manage on demand provisioning of cluster nodes.  Ray can be deployed on GKE clusters using a the kuberay k8s operator.

GKE provides the option for an out-of-the-box kuberay operator deployment. The version of kuberay is tied to the version of GKE you have deployed.  Currently these versions are supported:

* GKE 1.30 / kuberay 1.1.  
* GKE 1.31 / kuberay 1.2.

Alternatively, you can also deploy your own kuberay operator to get the latest kuberay 1.3 version.

The following sections describe in more details other required configuration settings required for Geneva to perform distributed execution.

### GKE node pools

GKE allows you to specify templates for virtual machines in "node pools".  These allow you to manage and configure resources such as the number of CPUs, number of GPUs, amount of memory, and if instances are spot or regular virtual machines.  

You can define your node pools however you want but Geneva uses three specific kubernetes labels to when deploying Ray pods on GKE: `ray-head`, `ray-worker-cpu`, `ray-worker-gpu`

Head nodes are where the Ray dashboard and scheduler run.  They should be non-spot instances and should not have processing workloads scheduled on them. Geneva 
looks for nodes with the `geneva.lancedb.com/ray-head` k8s label for this role.

CPU Worker nodes are where distributed processing that does not require GPU should be scheduled.  Geneva looks for nodes with the `geneva.lancedb.com/ray-worker-cpu` k8s label when these nodes are requested.

GPU Worker node are where distributed processing tha trequire GPU should be scheduled.  Geneval looks for nodes with the `geneva.lancedb.com/ray-worker-gpu` k8s label when these nodes are requested.

### GKE + k8s  Permissions

Geneva needs the ability to deploy a kuberay cluster and submit jobs to Ray. The workers in the Ray cluster need the ability to read and write to the Google Cloud Storage (GCS) buckets.  This requires setting up the proper k8s permissions and GCP IAM grants.  There are three main areas to setup and verify:

* Kubernetes Service Account (KSA)
* Google Service Account (GSA)
* GKE settings (GKE workload identity)

![Geneva security requirements](geneva-security-reqs.png)

[comment]: <> (link to drawing https://app.excalidraw.com/s/A3v4g07fw2r/9kR1DRHk36L)

In the following sections we'll use these variables

```
NAMESPACE=geneva  # replace with your actual namespace if different
KSA_NAME=geneva-ray-runner # replace with an identity name
PROJECT_ID=...  # replace with your google cloud project name
GSA_EMAIL=${KSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
LANCEDB_URI=gs://bucket/db  # replace with your own path
```

#### Kubernetes Service Account (KSA)

Inside your GKE cluster, you need a kubernetes service account which your provide the credentials your k8s pods (Ray) run with.  Here's how to create your KSA.

Create a Kubernetes service account (KSA)

```
kubectl create namespace $NAMESPACE   # skip if it already exists

kubectl create serviceaccount $KSA_NAME \
  --namespace $NAMESPACE
```

You can verify using 
```
kubectl get serviceaccounts -n $NAMESPACE $KSA_NAME
```

The Kubernetes service account (KSA) needs RBAC permissions inside the k8s cluster to provision Ray clusters via CRDs.  

Create a k8s role that can access the Ray CRD operations.
```
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${KSA_NAME}-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["ray.io"]
  resources: ["rayclusters"]
  verbs: ["get", "patch"]
EOF
```

Bind the clusterRole to your KSA

```
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${KSA_NAME}-binding
subjects:
- kind: ServiceAccount
  name: ${KSA_NAME}
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: ${KSA_NAME}-role
  apiGroup: rbac.authorization.k8s.io
EOF
```
Now confirm your permissions

```
kubectl auth can-i get pods --as=system:serviceaccount:${NAMESPACE}:${KSA_NAME}
```

#### Google service account (GSA)

To give your k8s workers the ability to read and write from your LanceDB buckets, your KSA needs to be bound to a Google Cloud service account (GSA) with those grants.  With this setup, any pod using the KSA will automatically get a token that lets it impersonate the GSA.

Let's set this up:

Create a google cloud service account

```
gcloud iam service-accounts create ${KSA_NAME} \
  --project=${PROJECT_ID} \
  --description="Service account for ray workloads in GKE" \
  --display-name="Ray Runner GSA"
```

You can verify this using:
```
gcloud iam service-accounts list --filter="displayName:Ray Runner GSA"
```

!!! Warning

    You need `roles/iam.serviceAccountAdmin` or minimally 
    `roles/iam.serviceAccountTokenCreator` rights to run these commands.

Next, you'll need to verify that your KSA is bound to your GSA and has has `roles/iam.workloadIdentityUser`
```
gcloud iam service-accounts get-iam-policy $GSA_EMAIL \
  --project=$PROJECT_ID \
  --format="json" | jq '.bindings[] | select(.role=="roles/iam.workloadIdentityUser")'
```

Give your GSA rights to access the LanceDB bucket.
```
gcloud storage buckets add-iam-policy-binding ${LANCEDB_URI}$ \
  --member="serviceAccount:${KSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```


#### GKE workload identity

A *GKE workload identity* is required to enable k8s workloads access Google Cloud services security and without needing to manually manage service account keys.  The workload identity is attached to Google Cloud service accounts (GSA) and mapped to a Kubernetes service account (KSA).  This feature needs to be enabled on the GKE cluster.

You can confirm that your workers have abilities to read/write to the LancedDB bucket.

```
kubectl run gcs-test --rm -it --image=google/cloud-sdk:slim \
  --serviceaccount=${KSA_NAME} \
  -n ${NAMESPACE} \
  -- bash
```

```
echo "hello" > test.txt
gsutil cp test.txt ${LANCEDB_URI}/demo-check/test-write.txt
```

Confirm the identity inside the pod
```
curl -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email    
```
