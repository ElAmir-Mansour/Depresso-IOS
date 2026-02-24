# Backend Deployment Guide (Render & Supabase)

This guide explains how to deploy the **Depresso Backend** for free using **Render** (Node.js hosting) and **Supabase** (PostgreSQL database). This is the recommended stack for your NLP research app.

## 1. Database Setup (Supabase)

1.  Go to [Supabase](https://supabase.com) and sign up (GitHub login recommended).
2.  Create a **New Project**.
    *   **Name:** `depresso-db`
    *   **Region:** Choose the one closest to you (e.g., Singapore/Hong Kong for Huawei synergy).
    *   **Password:** Generate a strong password and **save it**.
3.  Wait for the database to provision (takes ~1-2 mins).
4.  Once ready, go to **Settings (Gear Icon) -> Database**.
5.  Scroll down to **Connection String** -> **URI**.
6.  Copy the connection string. It looks like:
    `postgres://postgres:[YOUR-PASSWORD]@db.projectref.supabase.co:5432/postgres`
    *   Replace `[YOUR-PASSWORD]` with the password you created in step 2.
    *   **This is your `DATABASE_URL`.**

### Initialize Database Schema
1.  In Supabase, go to the **SQL Editor** (left sidebar).
2.  Click **New Query**.
3.  Open the `schema.sql` file from this project.
4.  Copy its contents and paste them into the SQL Editor.
5.  Click **Run**. This creates all the necessary tables.

## 2. Backend Deployment (Render)

1.  Push your code to **GitHub** (if you haven't already). Make sure the `depresso-backend` folder is in your repo.
2.  Go to [Render](https://render.com) and sign up.
3.  Click **New +** -> **Web Service**.
4.  Connect your GitHub repository.
5.  **Configure the Service:**
    *   **Name:** `depresso-api`
    *   **Region:** Match your database region if possible.
    *   **Branch:** `main` (or your working branch).
    *   **Root Directory:** `depresso-backend` (Important! Since your backend is in a subfolder).
    *   **Runtime:** `Node`
    *   **Build Command:** `npm install`
    *   **Start Command:** `npm start`
    *   **Instance Type:** Free (or Starter for $7/mo to avoid sleep).

6.  **Environment Variables:**
    Scroll down to "Environment Variables" and add the following:

    | Key | Value |
    | :--- | :--- |
    | `DATABASE_URL` | Paste your Supabase connection string from Step 1. |
    | `NODE_ENV` | `production` |
    | `GEMINI_API_KEY` | Your Google Gemini API Key |
    | `JWT_SECRET` | Generate a random string (e.g., `openssl rand -hex 32`) |

7.  Click **Create Web Service**.

## 3. Post-Deployment

1.  Wait for the deployment to finish. You will see a "Live" status.
2.  Render will give you a public URL (e.g., `https://depresso-api.onrender.com`).
3.  **Update your iOS App:**
    *   Open `APIClient.swift` in Xcode.
    *   Update `APIConfig.baseURL` to use this new URL.
    *   Example: `static let baseURL = "https://depresso-api.onrender.com/api/v1"`

## Troubleshooting

*   **Logs:** Check the "Logs" tab in Render if the deployment fails.
*   **Database Connection:** Ensure you appended `?sslmode=require` to your `DATABASE_URL` if connection fails (though our code handles SSL automatically).
