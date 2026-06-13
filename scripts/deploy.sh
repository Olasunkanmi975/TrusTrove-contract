#!/bin/bash
set -e

STELLAR="/mnt/c/Program Files (x86)/Stellar CLI/stellar.exe"

source .env.example

echo "=== Building all contracts ==="
"$STELLAR" contract build

echo ""
echo "=== Deploying registry_contract ==="
REGISTRY_ID=$("$STELLAR" contract deploy \
  --wasm target/wasm32v1-none/release/trusttrove_registry.wasm \
  --source $DEPLOYER_ACCOUNT \
  --network testnet)
echo "Registry: $REGISTRY_ID"
sleep 3

"$STELLAR" contract invoke \
  --id $REGISTRY_ID \
  --source $DEPLOYER_ACCOUNT \
  --network testnet \
  -- initialize \
  --admin $("$STELLAR" keys address $DEPLOYER_ACCOUNT)
sleep 3

echo ""
echo "=== Deploying invoice_contract ==="
INVOICE_ID=$("$STELLAR" contract deploy \
  --wasm target/wasm32v1-none/release/trusttrove_invoice.wasm \
  --source $DEPLOYER_ACCOUNT \
  --network testnet)
echo "Invoice: $INVOICE_ID"
sleep 3

"$STELLAR" contract invoke \
  --id $INVOICE_ID \
  --source $DEPLOYER_ACCOUNT \
  --network testnet \
  -- initialize \
  --admin $("$STELLAR" keys address $DEPLOYER_ACCOUNT) \
  --registry_contract $REGISTRY_ID
sleep 3

echo ""
echo "=== Deploying escrow_contract ==="
ESCROW_ID=$("$STELLAR" contract deploy \
  --wasm target/wasm32v1-none/release/trusttrove_escrow.wasm \
  --source $DEPLOYER_ACCOUNT \
  --network testnet)
echo "Escrow: $ESCROW_ID"
sleep 3

echo ""
echo "=== Deploying pool_contract ==="
POOL_ID=$("$STELLAR" contract deploy \
  --wasm target/wasm32v1-none/release/trusttrove_pool.wasm \
  --source $DEPLOYER_ACCOUNT \
  --network testnet)
echo "Pool: $POOL_ID"
sleep 3

echo ""
echo "=== Initializing escrow with pool and invoice addresses ==="
"$STELLAR" contract invoke \
  --id $ESCROW_ID \
  --source $DEPLOYER_ACCOUNT \
  --network testnet \
  -- initialize \
  --admin $("$STELLAR" keys address $DEPLOYER_ACCOUNT) \
  --pool_contract $POOL_ID \
  --invoice_contract $INVOICE_ID \
  --usdc_asset $USDC_ISSUER
sleep 3

echo ""
echo "=== Initializing pool ==="
"$STELLAR" contract invoke \
  --id $POOL_ID \
  --source $DEPLOYER_ACCOUNT \
  --network testnet \
  -- initialize \
  --admin $("$STELLAR" keys address $DEPLOYER_ACCOUNT) \
  --invoice_contract $INVOICE_ID \
  --escrow_contract $ESCROW_ID \
  --usdc_asset $USDC_ISSUER
sleep 3

echo ""
echo "=== Wiring pool_contract into invoice_contract ==="
"$STELLAR" contract invoke \
  --id $INVOICE_ID \
  --source $DEPLOYER_ACCOUNT \
  --network testnet \
  -- set_pool_contract \
  --pool_contract $POOL_ID
sleep 3

echo ""
echo "==========================================="
echo "Deployment complete. Add to trusttrove-app .env.local:"
echo ""
echo "NEXT_PUBLIC_REGISTRY_CONTRACT_ID=$REGISTRY_ID"
echo "NEXT_PUBLIC_INVOICE_CONTRACT_ID=$INVOICE_ID"
echo "NEXT_PUBLIC_ESCROW_CONTRACT_ID=$ESCROW_ID"
echo "NEXT_PUBLIC_POOL_CONTRACT_ID=$POOL_ID"
echo "==========================================="