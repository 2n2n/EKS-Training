# Jobs and CronJobs - Hands-On Guide

Welcome to the first workloads lab! In this guide, you'll work hands-on with Kubernetes Jobs and CronJobs to understand batch processing and scheduled tasks.

---

## 🎯 Learning Objectives

By the end of this guide, you will:

- ✅ Create and manage Kubernetes Jobs
- ✅ Configure job retries and parallelism
- ✅ Deploy CronJobs for scheduled tasks
- ✅ Monitor job execution and logs
- ✅ Clean up completed jobs automatically

---

## ⏱️ Time Estimate

**Total Time: 30-40 minutes**

- Understanding concepts: 10 min
- Hands-on with Jobs: 15 min
- Hands-on with CronJobs: 15 min

---

## 📋 Prerequisites

- Cluster from Activity 4 or 5 running
- kubectl configured
- Basic understanding of Pods and containers

---

## What Are Jobs?

**Jobs** create one or more Pods and ensure that a specified number of them successfully complete.

### 🏢 Traditional Equivalent

```bash
# Traditional: Run a script and hope it completes
/usr/local/bin/process-data.sh

# If it fails, manually re-run
# No tracking, no automatic retries
```

### ☁️ Kubernetes Job Benefits

```
✅ Automatic retries on failure
✅ Completion tracking
✅ Parallel execution
✅ Automatic cleanup
✅ Pod logs preserved
```

---

## Lab 1: Simple Job

### Step 1: Create a Simple Job

Let's create a job that calculates π to 2000 places:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculation
  namespace: default
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
EOF
```

**Configuration Explained:**
- `restartPolicy: Never`: Don't restart failed containers (create new pods instead)
- `backoffLimit: 4`: Try up to 4 times before marking as failed

### Step 2: Monitor the Job

```bash
# Watch job status
kubectl get jobs -w

# See the pods created
kubectl get pods --selector=job-name=pi-calculation

# Check job details
kubectl describe job pi-calculation
```

### Step 3: View Results

```bash
# Get pod name
POD_NAME=$(kubectl get pods --selector=job-name=pi-calculation -o jsonpath='{.items[0].metadata.name}')

# View the output
kubectl logs $POD_NAME

# You should see π calculated to 2000 decimal places!
```

### Step 4: Check Job Completion

```bash
# Job status
kubectl get job pi-calculation

# Output should show:
# NAME              COMPLETIONS   DURATION   AGE
# pi-calculation    1/1           30s        2m
```

### 💡 Understanding Job Status

```
Job Status Fields:
├── COMPLETIONS: 1/1 means "1 out of 1 required completions"
├── DURATION: Time taken to complete
└── AGE: Time since job was created

Pod Status:
├── Pending: Waiting to be scheduled
├── Running: Executing the task
├── Succeeded: Completed successfully
└── Failed: Failed (will retry based on backoffLimit)
```

---

## Lab 2: Job with Multiple Completions

### Step 1: Create a Job with Multiple Workers

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-processor
  namespace: default
spec:
  completions: 5          # Need 5 successful completions
  parallelism: 2          # Run 2 pods at a time
  template:
    spec:
      containers:
      - name: processor
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          echo "Processing batch item..."
          sleep 10
          echo "Batch item processed successfully!"
      restartPolicy: Never
  backoffLimit: 10
EOF
```

**Configuration Explained:**
- `completions: 5`: Job succeeds after 5 pods complete successfully
- `parallelism: 2`: Run maximum 2 pods concurrently
- Job will create pods in waves: 2, then 2, then 1

### Step 2: Watch Parallel Execution

```bash
# Watch pods being created in parallel
watch -n 1 kubectl get pods --selector=job-name=batch-processor

# You'll see:
# - First: 2 pods running
# - Then: Next 2 pods start after first 2 complete
# - Finally: Last pod runs
```

### Step 3: Monitor Progress

```bash
# Watch job progress
kubectl get job batch-processor -w

# Observe completions increase:
# 0/5 → 1/5 → 2/5 → 3/5 → 4/5 → 5/5
```

### 💡 Use Cases for Multiple Completions

```
Use parallelism when:
├── Processing large datasets in chunks
├── Running multiple test suites
├── Batch image processing
├── Data migration in parallel
└── Video encoding tasks
```

---

## Lab 3: Job with Failure Simulation

### Step 1: Create a Job That Fails Sometimes

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: flaky-job
  namespace: default
spec:
  template:
    spec:
      containers:
      - name: flaky
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting task..."
          # Randomly fail 50% of the time
          if [ $((RANDOM % 2)) -eq 0 ]; then
            echo "Task failed!"
            exit 1
          else
            echo "Task succeeded!"
            exit 0
          fi
      restartPolicy: Never
  backoffLimit: 5
EOF
```

### Step 2: Watch Retries

```bash
# Watch the job and its pods
kubectl get jobs,pods -l job-name=flaky-job -w

# You'll see multiple pods created until one succeeds
```

### Step 3: Check Failure History

```bash
# View job events showing retries
kubectl describe job flaky-job

# Look for events like:
# Created pod: flaky-job-xxxxx
# Back-off restarting failed container
```

### 💡 Backoff Limit Explained

```
backoffLimit: How many times to retry failed pods

Example with backoffLimit: 3:
1. Pod 1 fails → Create Pod 2
2. Pod 2 fails → Create Pod 3  
3. Pod 3 fails → Create Pod 4
4. Pod 4 fails → Job marked as Failed (reached limit)

Default: 6 retries
```

---

## Lab 4: CronJob - Scheduled Tasks

### What Are CronJobs?

**CronJobs** run Jobs on a schedule (like Linux cron).

### Step 1: Create a Simple CronJob

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-world
  namespace: default
spec:
  schedule: "*/2 * * * *"  # Every 2 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox:1.35
            command:
            - /bin/sh
            - -c
            - date; echo "Hello from Kubernetes CronJob!"
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
EOF
```

**Cron Schedule Syntax:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday=0)
│ │ │ │ │
│ │ │ │ │
* * * * *

Examples:
├── "*/5 * * * *"     Every 5 minutes
├── "0 * * * *"       Every hour (at minute 0)
├── "0 2 * * *"       Every day at 2:00 AM
├── "0 0 * * 0"       Every Sunday at midnight
└── "0 0 1 * *"       First day of every month at midnight
```

### Step 2: Monitor CronJob

```bash
# View CronJob
kubectl get cronjobs

# Output shows:
# NAME          SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
# hello-world   */2 * * * *   False     0        <none>          10s

# Wait 2 minutes and check again
kubectl get cronjobs
```

### Step 3: See Created Jobs

```bash
# After 2 minutes, CronJob creates a job
kubectl get jobs

# You'll see jobs named like: hello-world-28234567

# View the pods
kubectl get pods --selector=cronjob=hello-world
```

### Step 4: View Logs

```bash
# Get most recent pod name
POD_NAME=$(kubectl get pods --selector=job-name=hello-world-$(kubectl get jobs -o json | jq -r '.items[0].metadata.name' | cut -d'-' -f3) -o jsonpath='{.items[0].metadata.name}')

# View logs
kubectl logs $POD_NAME
```

---

## Lab 5: Database Backup CronJob (Realistic Example)

### Step 1: Create MySQL Database

First, let's deploy a simple MySQL instance (we'll use StatefulSets in the next guide):

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: "root123"
    - name: MYSQL_DATABASE
      value: "testdb"
    ports:
    - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
  clusterIP: None
EOF
```

### Step 2: Wait for MySQL to be Ready

```bash
kubectl wait --for=condition=ready pod/mysql --timeout=120s
```

### Step 3: Create Backup CronJob

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: default
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            command:
            - /bin/sh
            - -c
            - |
              echo "Starting backup at \$(date)"
              mysqldump -h mysql -uroot -proot123 testdb > /tmp/backup-\$(date +%Y%m%d-%H%M%S).sql
              echo "Backup completed: \$(ls -lh /tmp/backup-*.sql)"
              # In production, upload to S3/EBS volume here
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 7  # Keep last 7 successful backups
  failedJobsHistoryLimit: 3      # Keep last 3 failed attempts
EOF
```

### Step 4: Manually Trigger the Backup (for testing)

```bash
# Create a job from the CronJob manually
kubectl create job --from=cronjob/mysql-backup mysql-backup-manual

# Watch it run
kubectl get jobs -w

# View logs
kubectl logs job/mysql-backup-manual
```

---

## Lab 6: CronJob Concurrency Policy

### Understanding Concurrency Policies

```yaml
concurrencyPolicy: Controls how to handle overlapping jobs

Options:
├── Allow: Allow concurrent jobs (default)
├── Forbid: Skip new job if previous is still running
└── Replace: Cancel old job and start new one
```

### Step 1: Create Long-Running CronJob

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: slow-task
  namespace: default
spec:
  schedule: "*/1 * * * *"  # Every minute
  concurrencyPolicy: Forbid  # Don't start if previous is running
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: slow
            image: busybox:1.35
            command:
            - /bin/sh
            - -c
            - |
              echo "Started at \$(date)"
              sleep 120  # Takes 2 minutes (longer than schedule!)
              echo "Finished at \$(date)"
          restartPolicy: Never
EOF
```

### Step 2: Observe Skipped Runs

```bash
# Watch for a few minutes
kubectl get cronjobs,jobs -w

# You'll see:
# - First job starts
# - Next scheduled run is SKIPPED (job still running)
# - Another job starts after first completes
```

### Step 3: Check CronJob Events

```bash
kubectl describe cronjob slow-task

# Look for events showing skipped runs:
# "Not starting job because prior job is still running"
```

---

## 🧹 Cleanup

### Manual Cleanup

```bash
# Delete all jobs
kubectl delete job pi-calculation batch-processor flaky-job mysql-backup-manual

# Delete CronJobs
kubectl delete cronjob hello-world mysql-backup slow-task

# Delete MySQL
kubectl delete pod mysql
kubectl delete service mysql
```

### Automatic Cleanup with TTL

You can configure jobs to auto-delete after completion:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: auto-cleanup-job
spec:
  ttlSecondsAfterFinished: 100  # Delete 100 seconds after completion
  template:
    spec:
      containers:
      - name: task
        image: busybox:1.35
        command: ["echo", "I will be auto-deleted"]
      restartPolicy: Never
```

---

## 💡 Best Practices

### Job Configuration

```yaml
1. Set appropriate backoffLimit
   - Consider how many retries make sense
   - Default is 6 (might be too many)

2. Use restartPolicy wisely
   - Never: Create new pod on failure (recommended for Jobs)
   - OnFailure: Restart container in same pod (for CronJobs)

3. Set resource limits
   resources:
     requests:
       memory: "64Mi"
       cpu: "250m"
     limits:
       memory: "128Mi"
       cpu: "500m"

4. Add labels for easier management
   metadata:
     labels:
       app: backup
       component: database
```

### CronJob Best Practices

```yaml
1. Set history limits
   successfulJobsHistoryLimit: 3
   failedJobsHistoryLimit: 1
   # Prevents accumulation of old job objects

2. Use appropriate concurrencyPolicy
   concurrencyPolicy: Forbid
   # For jobs that shouldn't overlap (like backups)

3. Set startingDeadlineSeconds
   startingDeadlineSeconds: 200
   # If job can't start within 200s, consider it failed
   # Prevents late starts from queueing up

4. Monitor and alert
   # Use monitoring to track:
   - Job success/failure rate
   - Job duration
   - Missed schedules
```

---

## 🏢 Traditional vs Kubernetes

### Traditional Cron

```bash
# /etc/crontab
0 2 * * * /usr/local/bin/backup-db.sh

Problems:
❌ No retry logic
❌ No centralized logging
❌ Server-specific (not portable)
❌ No execution tracking
❌ Manual monitoring setup
```

### Kubernetes CronJob

```yaml
spec:
  schedule: "0 2 * * *"
  jobTemplate: ...

Benefits:
✅ Automatic retries (via Job)
✅ Centralized logs (kubectl logs)
✅ Portable (runs anywhere)
✅ Built-in tracking (job status)
✅ Easy monitoring (metrics)
```

---

## 🔍 Troubleshooting

### Job Not Starting

```bash
# Check job details
kubectl describe job <job-name>

# Common issues:
# - Image pull errors
# - Insufficient resources
# - Node selector constraints
```

### Job Keeps Failing

```bash
# View pod logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Review backoff limit
kubectl get job <job-name> -o yaml | grep backoffLimit
```

### CronJob Not Running

```bash
# Check CronJob status
kubectl get cronjob <cronjob-name>

# Verify schedule
kubectl describe cronjob <cronjob-name> | grep Schedule

# Check if suspended
kubectl get cronjob <cronjob-name> -o yaml | grep suspend
```

### Too Many Old Jobs

```bash
# Check history limits
kubectl get cronjob <cronjob-name> -o yaml | grep HistoryLimit

# Manually clean up old jobs
kubectl delete job --field-selector=status.successful=1
```

---

## 📚 Additional Resources

- [Kubernetes Jobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Kubernetes CronJobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Cron Schedule Generator](https://crontab.guru/)

---

## ✅ Knowledge Check

You should now be able to:

- [ ] Create and manage Jobs
- [ ] Configure job retries and parallelism
- [ ] Create CronJobs with proper schedules
- [ ] Understand concurrency policies
- [ ] Monitor job execution
- [ ] Clean up completed jobs

---

## 🚀 What's Next?

**Continue to:** [08-02-Secrets-And-ConfigMaps.md](08-02-Secrets-And-ConfigMaps.md) to learn about configuration management.

---

**Great job!** You now understand how to run batch and scheduled tasks in Kubernetes! 🎉

