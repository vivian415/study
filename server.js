const express = require("express");
const odbc = require("odbc");
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
require("dotenv").config();

const app = express();

app.use(express.json());

//
// API KEY CHECK
//
app.use((req, res, next) => {

  if (req.path === "/") {
    return next();
  }

  if (req.headers["x-api-key"] !== process.env.API_KEY) {
    return res.status(401).json({
      success: false,
      error: "Unauthorized"
    });
  }

  next();

});

//
// HEALTH CHECK
//
app.get("/", (req, res) => {

  res.json({
    success: true,
    message: "MCP Server Running"
  });

});

//
// SQL EXECUTION
//
app.post("/sql", async (req, res) => {

  const { sql } = req.body;

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

    console.log(err);

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// OPEN MEMBER
//
app.post("/open-member", async (req, res) => {

  const { library, file, member, ext = "txt" } = req.body;

  try {

    const connection = await odbc.connect(
  `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
);

    await connection.query(
      `CREATE OR REPLACE ALIAS QTEMP.MBRSRC
       FOR "${library}"."${file}"("${member}")`
    );

    const rows = await connection.query(
      "SELECT SRCDTA FROM QTEMP.MBRSRC ORDER BY SRCSEQ"
    );

    await connection.close();

    const dirPath = path.join(
      __dirname,
      "workspace",
      library,
      file
    );

    fs.mkdirSync(dirPath, { recursive: true });

    const filePath = path.join(
      dirPath,
      `${member}.${ext}`
    );

    const text = rows.map(r => r.SRCDTA).join("\n");

    fs.writeFileSync(filePath, text, "utf8");

    exec(`code "${filePath}"`);

    res.json({
      success: true,
      filePath
    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// SAVE MEMBER
//
app.post("/save-member", async (req, res) => {

  const { library, file, member, ext = "txt" } = req.body;

  try {

    const filePath = path.join(
      __dirname,
      "workspace",
      library,
      file,
      `${member}.${ext}`
    );

    if (!fs.existsSync(filePath)) {

      return res.status(404).json({
        success: false,
        error: "local file not found"
      });

    }

    const text = fs.readFileSync(filePath, "utf8");

    const lines = text
      .replace(/\r\n/g, "\n")
      .split("\n");

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
    );

    await connection.query(
      `CREATE OR REPLACE ALIAS QTEMP.MBRSRC
       FOR "${library}"."${file}"("${member}")`
    );

    await connection.query(
      "DELETE FROM QTEMP.MBRSRC"
    );

    for (let i = 0; i < lines.length; i++) {

      const seq = (i + 1).toFixed(2);

      await connection.query(
        "INSERT INTO QTEMP.MBRSRC (SRCSEQ, SRCDAT, SRCDTA) VALUES (?, ?, ?)",
        [seq, 0, lines[i]]
      );

    }

    await connection.close();

    res.json({
      success: true,
      message: "member saved",
      lines: lines.length
    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// COMPILE RPG
//
app.post("/compile-rpg", async (req, res) => {

  const { targetlib, srclib, srcfile, member } = req.body;

  console.log("HOST=", process.env.IBMI_HOST);
  console.log("USER=", process.env.IBMI_USER);
  console.log("PWD=", process.env.IBMI_PASSWORD ? "***" : "EMPTY");

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
    );

    const sql =
      `CALL QSYS2.QCMDEXC('CRTBNDRPG PGM(${targetlib}/${member}) SRCFILE(${srclib}/${srcfile}) SRCMBR(${member})')`;

    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      sql
    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// SERVER START
//
app.listen(3000, "0.0.0.0", () => {

  console.log("server running on http://localhost:3000");

  console.log(
    "IBMI_HOST:",
    process.env.IBMI_HOST
  );

  console.log(
    "IBMI_USER:",
    process.env.IBMI_USER
  );

  console.log(
    "IBMI_PASSWORD:",
    process.env.IBMI_PASSWORD ? "***" : "EMPTY"
  );

  console.log(
    "API_KEY:",
    process.env.API_KEY ? "***" : "EMPTY"
  );

});