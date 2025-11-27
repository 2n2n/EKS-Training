# AWS CLI Setup and Configuration

**Estimated Time: 15 minutes**

---

## 🎯 What You'll Do

1. Install AWS CLI version 2
2. Configure with your AWS credentials
3. Test the connection
4. Verify everything works

---

## 📥 Installation

### macOS

**Method 1: Homebrew (Recommended)**

```bash
# Install Homebrew first (if not installed):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install AWS CLI:
brew install awscli

# Verify:
aws --version
```

**Method 2: Official Installer**

```bash
# Download and install:
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify:
aws --version
```

### Linux

**Ubuntu/Debian:**

```bash
# Download and install:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify:
aws --version
```

**Amazon Linux 2:**

```bash
# AWS CLI v2 is pre-installed
# If not:
sudo yum install aws-cli

# Verify:
aws --version
```

### Windows

**Method 1: Official Installer (Recommended)**

1. Download: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Run the installer
3. Follow the installation wizard
4. Open Command Prompt or PowerShell
5. Verify:

```powershell
aws --version
```

**Method 2: Chocolatey**

```powershell
# Install Chocolatey first: https://chocolatey.org/install
# Then install AWS CLI:
choco install awscli

# Verify:
aws --version
```

---

## ⚙️ Configuration

### Step 1: Get Your AWS Credentials

You need:
- **Access Key ID** (starts with AKIA...)
- **Secret Access Key**

**How to get them:**

1. Log into AWS Console
2. Go to **IAM** service
3. Click **Users** → Your username
4. Go to **Security credentials** tab
5. Click **Create access key**
6. Choose **Command Line Interface (CLI)**
7. Download or copy the credentials

⚠️ **Important:** Save these! You won't see the Secret Access Key again!

### Step 2: Configure AWS CLI

```bash
aws configure
```

**You'll be prompted for:**

```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

**Region codes:**
- `ap-southeast-1` = Singapore (we'll use this)
- `us-east-1` = N. Virginia, USA
- `us-west-2` = Oregon, USA
- `eu-west-1` = Ireland, Europe

**Output formats:**
- `json` (recommended)
- `yaml`
- `text`
- `table`

### Step 3: Verify Configuration

```bash
# Test connection:
aws sts get-caller-identity
```

**Expected output:**

```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

If you see this, you're configured correctly! ✅

---

## 🔧 Advanced Configuration

### Multiple Profiles

If you have multiple AWS accounts:

```bash
# Configure with profile name:
aws configure --profile work
aws configure --profile personal

# Use specific profile:
aws s3 ls --profile work

# Set default profile:
export AWS_PROFILE=work
```

### Configuration Files

AWS CLI stores config in:

```bash
# Linux/macOS:
~/.aws/credentials  # Access keys
~/.aws/config       # Region, output format

# Windows:
C:\Users\USERNAME\.aws\credentials
C:\Users\USERNAME\.aws\config
```

**Example ~/.aws/credentials:**

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[work]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```

**Example ~/.aws/config:**

```ini
[default]
region = ap-southeast-1
output = json

[profile work]
region = us-east-1
output = yaml
```

### Environment Variables

Alternative to `aws configure`:

```bash
# Set environment variables:
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=ap-southeast-1

# Add to ~/.bashrc or ~/.zshrc to persist
```

---

## ✅ Testing

### Basic Tests

```bash
# 1. Check your identity:
aws sts get-caller-identity

# 2. List S3 buckets (if any):
aws s3 ls

# 3. List EC2 instances (if any):
aws ec2 describe-instances --region ap-southeast-1

# 4. Check EKS clusters (if any):
aws eks list-clusters --region ap-southeast-1
```

### Test Permissions

```bash
# Test if you can create EKS resources:
aws eks list-clusters

# Expected:
{
    "clusters": []
}

# Or error message if no permissions
```

---

## 🚫 Common Issues

### Issue: "aws: command not found"

**Cause:** AWS CLI not in PATH

**Solution:**

```bash
# Find where aws is installed:
find / -name aws 2>/dev/null

# Add to PATH (example):
export PATH=$PATH:/usr/local/bin

# Make permanent:
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Unable to locate credentials"

**Cause:** Not configured

**Solution:**

```bash
aws configure
# Enter your credentials
```

### Issue: "InvalidClientTokenId"

**Cause:** Invalid Access Key

**Solution:**

1. Verify Access Key is correct
2. Create new access key in AWS Console
3. Run `aws configure` again

### Issue: "Access Denied"

**Cause:** IAM user lacks permissions

**Solution:**

1. Go to AWS Console → IAM → Users
2. Attach policies:
   - `AmazonEKSClusterPolicy`
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`

---

## 💡 Pro Tips

### 1. Use Command Completion

```bash
# Bash:
complete -C '/usr/local/bin/aws_completer' aws

# Add to ~/.bashrc:
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
```

### 2. Use --query to Filter Output

```bash
# Get only instance IDs:
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'

# Get only cluster names:
aws eks list-clusters --query 'clusters[]'
```

### 3. Use --output for Different Formats

```bash
# JSON (default):
aws eks list-clusters --output json

# Table (easier to read):
aws eks list-clusters --output table

# YAML:
aws eks list-clusters --output yaml
```

### 4. Use --dry-run for Safety

```bash
# Test command without executing:
aws ec2 run-instances --dry-run --image-id ami-12345 --instance-type t3.micro
```

---

## 📚 Essential AWS CLI Commands for EKS

```bash
# EKS:
aws eks list-clusters
aws eks describe-cluster --name my-cluster
aws eks update-kubeconfig --name my-cluster

# EC2:
aws ec2 describe-instances
aws ec2 describe-vpcs
aws ec2 describe-subnets

# IAM:
aws iam list-roles
aws iam get-role --role-name EKSClusterRole

# CloudFormation (eksctl uses this):
aws cloudformation list-stacks
aws cloudformation describe-stacks --stack-name eksctl-my-cluster
```

---

## ✅ Success Criteria

You're ready to proceed when:

- [ ] `aws --version` shows AWS CLI 2.x
- [ ] `aws sts get-caller-identity` returns your account info
- [ ] `aws eks list-clusters` works (even if empty)
- [ ] No "Access Denied" or "Invalid Credentials" errors

---

## 🚀 Next Steps

**AWS CLI installed and configured?** 

Move to: [02-Kubectl-Setup.md](02-Kubectl-Setup.md)

---

## 📖 Additional Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [AWS CLI on GitHub](https://github.com/aws/aws-cli)

