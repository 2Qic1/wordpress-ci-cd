#!/usr/bin/env python3
import requests
import json
import time
import sys
import os

WEBHOOK_URL = "https://discordapp.com/api/webhooks/1409577998444793856/TAduFB3cR-Ip3CxquarZbn99cvKUKTuJFonE8kVxosxbUTtFZVTF-haqyPw8GPZkANmG"

def send_discord_message(message, deployment_time=None):
    data = {
        "content": message,
        "username": "CI/CD Bot",
        "embeds": []
    }
    
    if deployment_time:
        embed = {
            "title": "Deployment Statistics",
            "color": 0x00ff00,
            "fields": [
                {
                    "name": "Deployment Time",
                    "value": f"{deployment_time:.2f} seconds",
                    "inline": True
                },
                {
                    "name": "Status",
                    "value": "✅ Successful",
                    "inline": True
                }
            ]
        }
        data["embeds"].append(embed)
    
    response = requests.post(WEBHOOK_URL, json=data)
    return response.status_code == 204

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        start_time = float(sys.argv[2]) if len(sys.argv) > 2 else time.time()
        
        if action == "start":
            send_discord_message("🚀 Deployment started!")
        elif action == "success":
            end_time = time.time()
            deployment_time = end_time - start_time
            send_discord_message("✅ Deployment completed successfully!", deployment_time)
        elif action == "fail":
            send_discord_message("❌ Deployment failed!")
