const express = require("express");
const { Client } = require("ssh2");
const readline = require("readline");
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
require("dotenv").config();

const app = express();
app.use(express.json());

const odbc = require("odbc");

// APIキー（残すならOK）
app.use((req, res, next) => {
  if (req.path === "/" || req.path === "/health") 
    return next();

  if (req.headers["x-api-key"] !== process.env.API_KEY) {
    return res.status(401).send("Unauthorized");
  }

  next();
});


// IBM iコマンド実行
function runIBMi(command, callback) {
  const conn = new Client();

  const cmd = (command || "").trim().toUpperCase();

const ALLOWED_COMMANDS = new Set([
  "ECHO",
  "UNAME",
  "DB2",
  "CRTBNDRPG",
  "CRTDSPF",
  "CRTPF",
  "CRTLF",
  "RMVM",
  "ADDPFM",
  "SYSTEM"  // ← これ追加

]);

  const baseCommand = cmd.split(" ")[0];

if (!ALLOWED_COMMANDS.has(baseCommand)) {
  return callback("Blocked command");
}

  let finished = false;
  let connClosed = false;

  function safeFinish(result) {
    if (finished) return;
    finished = true;

    clearTimeout(timeout);

    if (!connClosed) {
      connClosed = true;
      try {
        conn.end();
      } catch {}
    }

    callback(result);
  }

  const timeout = setTimeout(() => {
    safeFinish("Timeout");
  }, 10000);

conn.on("ready", () => {
  conn.exec(cmd, { pty: false }, (err, stream) => {
    if (err) {
      return safeFinish(`Error: ${err.message}`);
    }

    let stdout = "";
    let stderr = "";

    stream.on("data", (d) => {
      stdout += d.toString("utf8");
    });

    if (stream.stderr) {
      stream.stderr.on("data", (d) => {
        stderr += d.toString("utf8");
      });
    }

    stream.on("close", (code, signal) => {
      safeFinish({
        code,
        signal,
        stdout,
        stderr
      });
    });
  });
});


conn.on("error", (err) => {
  safeFinish(`SSH ERROR: ${err.message}`);
});

conn.connect({
    host: process.env.IBMI_HOST,
    port: 22,
    username: process.env.IBMI_USER,
    password: process.env.IBMI_PASSWORD
  });
}
 
// テスト
app.get("/", (req, res) => {
  res.send("OK");
});

// ライブラリ確認（今はダミーでもOK）
app.get("/libraries", (req, res) => {
  res.json({ ok: true });
});

// IBM iコマンド実行
app.post("/run", (req, res) => {
  console.log("RUN HIT");
  console.log("BODY:", req.body);

  console.log("IBMI_HOST:", process.env.IBMI_HOST);
  console.log("IBMI_USER:", process.env.IBMI_USER);
  console.log("IBMI_PASSWORD:", process.env.IBMI_PASSWORD ? "***" : "EMPTY");

  const { command } = req.body;

  if (!command) {
    return res.status(400).json({ error: "command is required" });
  }

  runIBMi(command, (output) => {
    res.json({
      success: true,
      command,
      output
    });
  });
});

// SQL実行（ODBC）
app.post("/sql", async (req, res) => {
  const { sql } = req.body;

  if (!sql) {
    return res.status(400).json({ error: "sql is required" });
  }

  try {
    const connection = await odbc.connect(
  `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
);

    const result = await connection.query(sql);
    await connection.close();

    res.json({
      success: true,
      rows: result
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message
    });
  }
});

// メンバーソース取得
app.post("/member-source", async (req, res) => {
  const { library, file, member } = req.body;

  try {
    const connection = await odbc.connect(
  `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
);

    await connection.query(
      `CREATE OR REPLACE ALIAS QTEMP.MBRSRC FOR ${library}.${file}(${member})`
    );

    const result = await connection.query(
      "SELECT SRCSEQ, SRCDAT, SRCDTA FROM QTEMP.MBRSRC ORDER BY SRCSEQ"
    );

    await connection.close();

    res.json({
      success: true,
      rows: result
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message
    });
  }
});

app.post("/open-member", async (req, res) => {
  const { library, file, member, ext = "cl" } = req.body;

  try {
    const connection = await odbc.connect(
  `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
);

    await connection.query(
      `CREATE OR REPLACE ALIAS QTEMP.MBRSRC FOR ${library}.${file}(${member})`
    );

    const rows = await connection.query(
      "SELECT SRCDTA FROM QTEMP.MBRSRC ORDER BY SRCSEQ"
    );

    await connection.close();

    const dir = path.join(__dirname, "workspace");
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);

    const filePath = path.join(dir, `${library}_${file}_${member}.${ext}`);
    const text = rows.map(r => r.SRCDTA).join("\n");

   fs.writeFileSync(filePath, text, "utf8");

    exec(`code "${filePath}"`);

    res.json({
      success: true,
      filePath
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message
    });
  }
});

// メンバー書き戻し
app.post("/save-member", async (req, res) => {
  const { library, file, member, ext = "txt" } = req.body;

  try {
    const filePath = path.join(__dirname, "workspace", `${library}_${file}_${member}.${ext}`);

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ success: false, error: "local file not found" });
    }

    const text = fs.readFileSync(filePath, "utf8");
    const lines = text.replace(/\r\n/g, "\n").split("\n");

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
    );

    await connection.query(
      `CREATE OR REPLACE ALIAS QTEMP.MBRSRC FOR ${library}.${file}(${member})`
    );

    // 既存メンバー内容を削除
    await connection.query("DELETE FROM QTEMP.MBRSRC");

    // 行単位で書き戻し
    for (let i = 0; i < lines.length; i++) {
      const seq = (i + 1).toFixed(2);
      const srcdat = 0;
      const srcdta = lines[i];

      await connection.query(
        "INSERT INTO QTEMP.MBRSRC (SRCSEQ, SRCDAT, SRCDTA) VALUES (?, ?, ?)",
        [seq, srcdat, srcdta]
      );
    }

    await connection.close();

    res.json({
      success: true,
      message: "member saved",
      library,
      file,
      member,
      lines: lines.length
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message
    });
  }
});

// 起動
app.listen(3000, "0.0.0.0", () => {
  console.log("server running on http://localhost:3000");
  console.log("IBMI_HOST:", process.env.IBMI_HOST);
  console.log("IBMI_USER:", process.env.IBMI_USER);
  console.log("IBMI_PASSWORD:", process.env.IBMI_PASSWORD ? "***" : "EMPTY");
  console.log("API_KEY:", process.env.API_KEY ? "***" : "EMPTY");
});