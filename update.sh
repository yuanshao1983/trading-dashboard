#!/bin/bash
# 剃刀仪表盘数据同步 + GitHub推送
set -e

DASHBOARD_DIR="$HOME/trading-dashboard"
HERMES_DIR="$HOME/.hermes"
HERMES_VENV="$HERMES_DIR/hermes-agent/venv/bin/python3"

# Step 0: 全市场广度扫描（5300+只，仅剥ST/停牌/920）
echo "🌐 全市场广度扫描..."
$HERMES_VENV "$HERMES_DIR/scripts/all_market_breadth.py" 2>&1

# Step 1: DNA账本固化（评分→交易记录→权重修正→持仓DNA）
echo "🧬 DNA账本固化..."
$HERMES_VENV "$HERMES_DIR/scripts/dna_ledger.py" all 2>&1

# Step 2: 数据聚合（含全市场广度）
echo "📊 数据聚合..."
$HERMES_VENV "$HERMES_DIR/scripts/data_aggregator.py" aggregate 2>&1

# Step 3: 同步数据
cp "$HERMES_DIR/paper_account.json" "$DASHBOARD_DIR/data/"
cp "$HERMES_DIR/data/trades.json" "$DASHBOARD_DIR/data/" 2>/dev/null || true
cp "$HERMES_DIR/cache/all_market_breadth.json" "$DASHBOARD_DIR/data/" 2>/dev/null || true

# Step 4: 归档
ARCHIVE_DIR="$DASHBOARD_DIR/data/archive/$(date +%Y-%m-%d)"
mkdir -p "$ARCHIVE_DIR"
cp "$DASHBOARD_DIR/data/"*.json "$ARCHIVE_DIR/" 2>/dev/null || true

# Step 5: git push
cd "$DASHBOARD_DIR"
git add data/
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
git commit -m "auto: $TIMESTAMP" || true
git push 2>&1

echo "Dashboard updated: $TIMESTAMP"
