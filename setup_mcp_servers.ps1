# ============================================================
# MCP Server Setup for VS Code Copilot (Agent Mode)
# ============================================================
# Prerequisites: Docker Desktop, Azure CLI, Node.js, uv (Python)
# Run this script in an elevated (admin) PowerShell terminal.
# Usage: .\setup_mcp_servers.ps1 -TenantId "<your-tenant-id>"
# ============================================================

param(
  [Parameter(Mandatory = $true, HelpMessage = "Azure tenant ID to use for az login")]
  [string]$TenantId
)

# --- Step 1: Install prerequisites (uncomment if needed) ---
# winget install -e --id Docker.DockerDesktop
# winget install -e --id Microsoft.AzureCLI
# winget install -e --id OpenJS.NodeJS
# irm https://astral.sh/uv/install.ps1 | iex   # installs uv + uvx

# --- Step 2: Install MCP server CLIs ---
Write-Host "📦 Installing MCP server tools..." -ForegroundColor Cyan

# Azure MCP Server (provides the 'azmcp' command)
Write-Host "  Installing Azure MCP Server..."
npm install -g @azure/mcp@latest

# Refresh PATH so newly installed tools are found in this session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Pull Terraform MCP Docker image ahead of time
Write-Host "  Pulling Terraform MCP Docker image..."
docker pull hashicorp/terraform-mcp-server

# Pre-install Python-based MCP servers so first launch is fast
Write-Host "  Pre-installing Python MCP servers (uv)..."
uv tool install mcp-server-fetch 2>$null
uv tool install mcp-server-git 2>$null
uv tool install avm-mcp-server 2>$null
Write-Host "  Done." -ForegroundColor Green

# --- Step 3: Verify installations ---
Write-Host "`n🔍 Verifying installations..." -ForegroundColor Cyan
$tools = @("docker", "azmcp", "npx", "uvx")
$allGood = $true
foreach ($tool in $tools) {
  $found = Get-Command $tool -ErrorAction SilentlyContinue
  if ($found) {
    Write-Host "  ✅ $tool found at $($found.Source)" -ForegroundColor Green
  }
  else {
    Write-Host "  ❌ $tool NOT FOUND - some MCP servers will fail to start" -ForegroundColor Red
    $allGood = $false
  }
}

# --- Step 4: Azure login ---
Write-Host "`n🔑 Logging into Azure..." -ForegroundColor Cyan
az login --tenant $TenantId

# --- Step 5: Write MCP config ---
$McpPath = "$env:APPDATA\Code\User\mcp.json"
New-Item -ItemType File -Force -Path $McpPath | Out-Null

# Notes:
#   - Bicep MCP is provided by the VS Code Bicep extension (no CLI entry needed)
#   - To add later: Kubernetes (needs kubeconfig), Azure DevOps (needs ADO org),
#     PostgreSQL (needs connection string), SQL Server (needs connection details),
#     GitHub (needs a Personal Access Token)

# Build MCP config using PowerShell objects to avoid JSON escaping issues
$config = @{
  servers = [ordered]@{
    terraform  = [ordered]@{
      type    = "stdio"
      command = (Get-Command docker -ErrorAction SilentlyContinue).Source
      args    = @("run", "-i", "--rm", "hashicorp/terraform-mcp-server")
    }
    azure      = [ordered]@{
      type    = "stdio"
      command = (Get-Command azmcp.cmd -ErrorAction SilentlyContinue).Source
      args    = @("server", "start", "--transport=stdio")
    }
    avm        = [ordered]@{
      type    = "stdio"
      command = (Get-Command uvx.exe -ErrorAction SilentlyContinue).Source
      args    = @("avm-mcp-server")
    }
    filesystem = [ordered]@{
      type    = "stdio"
      command = (Get-Command npx.cmd -ErrorAction SilentlyContinue).Source
      args    = @("-y", "@modelcontextprotocol/server-filesystem", "C:\Users\kavehalemi\OneDrive - Microsoft\Documents")
    }
    fetch      = [ordered]@{
      type    = "stdio"
      command = (Get-Command uvx.exe -ErrorAction SilentlyContinue).Source
      args    = @("mcp-server-fetch")
    }
    git        = [ordered]@{
      type    = "stdio"
      command = (Get-Command uvx.exe -ErrorAction SilentlyContinue).Source
      args    = @("mcp-server-git")
    }
  }
}
$config | ConvertTo-Json -Depth 4 | Set-Content -Path $McpPath -Encoding UTF8

Write-Host "`n📄 MCP config written to: $McpPath" -ForegroundColor Cyan

if ($allGood) {
  Write-Host "✅ All MCP server tools are installed. Restart VS Code to activate." -ForegroundColor Green
}
else {
  Write-Host "⚠️  Some tools are missing. Fix the errors above, then re-run this script." -ForegroundColor Yellow
  Write-Host "   After fixing, restart VS Code for changes to take effect." -ForegroundColor Yellow
}

Write-Host "`n📋 Configured MCP servers:" -ForegroundColor Cyan
Write-Host "  • terraform   — Terraform registry & provider tools (Docker)"
Write-Host "  • azure       — Azure resource management (azmcp)"
Write-Host "  • avm         — Azure Verified Modules catalog (uvx)"
Write-Host "  • filesystem  — File system access to Documents folder (npx)"
Write-Host "  • fetch       — Web content fetching (uvx)"
Write-Host "  • git         — Git operations (uvx)"
Write-Host ""
Write-Host "  Provided by VS Code extensions (no config needed):" -ForegroundColor DarkGray
Write-Host "    • bicep     — Install 'ms-azuretools.vscode-bicep' extension" -ForegroundColor DarkGray