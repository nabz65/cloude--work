# Add basic documentation
echo "# System Health & Alerting Daemon" > README.md
echo "Automated Bash daemon monitoring CPU, RAM, and Disk metrics via Cron." >> README.md

# Git Commit Workflow
git add .
git commit -m "feat: complete v1.0 system health daemon script and cron integration"
git log --oneline
