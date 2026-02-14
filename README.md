# IoT-Project
IoT_Project test
n8n 後端使用說明
n8n 負責處理 Webhook 請求、AI 決策 (Gemini) 以及 PostgreSQL 資料庫的寫入與讀取。
啟動環境
電腦已安裝 Docker下，在 n8n_server/ 目錄下執行：
docker-compose up -d
啟動後，透過瀏覽器進入 
http://localhost:5678 存取 n8n 介面。
2. 匯入工作流 (Workflows)
在 n8n 介面點擊左側選單的 Workflows
點擊右上角的 Import from File。
選擇本專案 n8n_server/workflows/ 資料夾下的 .json 檔案。
匯入後確認 Postgres 節點 已連結到資料庫帳號。
