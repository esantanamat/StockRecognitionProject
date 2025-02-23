# Grocery Store Stock Recognition Using AWS Rekognition

## Overview

This project automates **inventory tracking** using **AWS Rekognition**. By capturing images of grocery store shelves, the system **identifies and tracks stock levels** automatically.
Note: You will need to train your own **AWS Rekognition Custom Labels model**

## Tech Stack

- **AWS Rekognition** – Detects grocery items from images
- **AWS Lambda** – Processes images and updates stock data
- **Amazon S3** – Stores uploaded images
- **Amazon DynamoDB** – Maintains stock levels
- **Python** – Backend logic
- **Terraform** – AWS resource provisioning

## How It Works

1. 📸 **Image is captured or uploaded**
2. ☁️ **Stored in Amazon S3**
3. 🧠 **AWS Rekognition detects items**
4. 🔄 **Lambda updates DynamoDB with stock levels**
![Architecture Diagram] (./architecture-diagram.png)

## Setup & Deployment

```sh
git clone https://github.com/esantanamat/recognitionproject.git
cd recognitionproject
terraform init
terraform apply

```

## Future Enhancements

- Train a **custom Rekognition model** for better accuracy
- Build a **frontend dashboard** for real-time stock monitoring
