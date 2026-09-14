# retail-store-terraform


# Configure Backend S3
aws configure get region

aws s3 mb s3://retail-store-tfstate-745838912158 --region <ta-région>

# Activer le versioning (obligatoire pour le lockfile natif)
aws s3api put-bucket-versioning \
  --bucket retail-store-tfstate-745838912158 \
  --versioning-configuration Status=Enabled

# Chiffrement par défaut du contenu du bucket (le state peut contenir des secrets en clair)
aws s3api put-bucket-encryption \
  --bucket retail-store-tfstate-745838912158 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Bloquer tout accès public — le state ne doit JAMAIS être accessible publiquement
aws s3api put-public-access-block \
  --bucket retail-store-tfstate-745838912158 \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Login to ecr and push images :
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 745838912158.dkr.ecr.eu-north-1.amazonaws.com

docker tag catalog:dev 745838912158.dkr.ecr.eu-north-1.amazonaws.com/retail-store/catalog:dev
docker push 745838912158.dkr.ecr.eu-north-1.amazonaws.com/retail-store/catalog:dev

# Install  ESO :

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --version 2.9.0 \
  --namespace external-secrets \
  --create-namespace

/!\ Créer le rôle IAM pour ESO
kubectl describe pod -n external-secrets -l app.kubernetes.io/name=external-secrets | grep -A3 AWS_


kubectl apply -f clustersecretstore-parameterstore.yaml
kubectl apply -f clustersecretstore-secretsmanager.yaml

# Install ArgoCD

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm search repo argo/argo-cd --versions | head -5

kubectl create namespace argocd

helm install argocd argo/argo-cd \
  --namespace argocd \
  --version <version-vérifiée-à-l'étape-précédente>

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d

kubectl port-forward svc/argocd-server -n argocd 8080:443

kubectl apply -f argocd/application.yaml