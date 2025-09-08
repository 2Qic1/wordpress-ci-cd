.PHONY: deploy-v1 deploy-v2 deploy-v3 rollback

deploy-v1:
@echo "Deploying version v1..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v1"}}'
@echo "Version v1 deployed"

deploy-v2:
@echo "Deploying version v2..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v2"}}'
@echo "Version v2 deployed"

deploy-v3:
@echo "Deploying version v3 (broken)..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v3"}}'
@echo "Version v3 deployed"

rollback:
@echo "Rolling back to previous version..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v1"}}'
@echo "Rollback completed"

status:
@echo "Current version: $$(kubectl get configmap wordpress-config -o jsonpath='{.data.app-version}')"

test-webhook:
python3 discord/webhook.py test
