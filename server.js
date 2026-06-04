const express = require("express");
const odbc = require("odbc");
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
require("dotenv").config();

// ===== PC workspace root =====

const LOCAL_ROOT =
  "C:/Users/K4293/mcp-server/workspace";

// ===== TYPE → extension =====

function getExtension(type) {

  const map = {
    RPGLE: "rpgle",
    RPG: "rpg",
    CLLE: "clle",
    PF: "pf",
    DSPF: "dspf",
    PRTF: "prtf",
    TXT: "txt",
    SQLRPGLE: "sqlrpgle"
  };

  return map[type.toUpperCase()] || "txt";
}

// ===== build local path =====

function buildLocalPath(
  library,
  srcFile,
  member,
  type
) {

  const ext = getExtension(type);

  return path.join(
    LOCAL_ROOT,
    library,
    srcFile,
    `${member}.${ext}`
  );
}

// ===== ensure directory =====

function ensureDir(filePath) {

  const dir = path.dirname(filePath);

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, {
      recursive: true
    });
  }
}

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

  const {
    library,
    srcFile,
    member,
  } = req.body;

  try {

    const connection = await odbc.connect(
  `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
);

const aliasSql = `
CREATE OR REPLACE ALIAS QTEMP.MBRSRC
FOR "${library}"."${srcFile}"("${member}")
`;

console.log("ALIAS SQL");
console.log(aliasSql);

await connection.query(aliasSql);



//
// codembr
//

const typeSql = `
SELECT SOURCE_TYPE
FROM QSYS2.SYSPARTITIONSTAT
WHERE TABLE_SCHEMA = '${library}'
  AND TABLE_NAME = '${srcFile}'
  AND TRIM(SYSTEM_TABLE_MEMBER) = '${member}'
`;

const typeRows = await connection.query(typeSql);

console.dir(typeRows, { depth: null });


const sourceType =
  typeRows[0]?.SOURCE_TYPE || "TXT";

  const ext =
  getExtension(sourceType);

 console.log(
  `SRCTYPE=${sourceType} EXT=${ext}`
); 


const sql = `
SELECT SRCDTA
FROM QTEMP.MBRSRC
ORDER BY SRCSEQ
`;

console.log("SELECT SQL");
console.log(sql);

const rows = await connection.query(sql);

console.log(rows);
    await connection.close();

    const dirPath = path.join(
      __dirname,
      "workspace",
      library,
      srcFile
    );

    fs.mkdirSync(dirPath, { recursive: true });

    const filePath = path.join(
      dirPath,
      `${member}.${ext}`
    );

    const text = rows.map(r => r.SRCDTA).join("\n");

    console.log(text);
    
    fs.writeFileSync(filePath, text, "utf8");

    exec(`code "${filePath}"`);

    res.json({
      success: true,
      filePath
    });

  } catch (err) {

   console.dir(err, { depth: null });

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

  const { library, file, member, ext } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;`
    );

    const typeSql = `
SELECT SOURCE_TYPE
FROM QSYS2.SYSPARTITIONSTAT
WHERE TABLE_SCHEMA = '${library}'
  AND TABLE_NAME = '${file}'
  AND TRIM(SYSTEM_TABLE_MEMBER) = '${member}'
`;

    const typeRows = await connection.query(typeSql);
    const sourceType = typeRows[0]?.SOURCE_TYPE || "TXT";
    const saveExt = ext || getExtension(sourceType);

    const filePath = path.join(
      __dirname,
      "workspace",
      library,
      file,
      `${member}.${saveExt}`
    );

    if (!fs.existsSync(filePath)) {
      await connection.close();

      return res.status(404).json({
        success: false,
        error: "local file not found"
      });

    }

    const text = fs.readFileSync(filePath, "utf8");

    const lines = text
      .replace(/\r\n/g, "\n")
      .split("\n");

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
      lines: lines.length,
      ext: saveExt
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
// COPY SOURCE FILE
//
app.post("/copy-src", async (req, res) => {

  const {
  fromLib,
  srcFile,
  toLib
} = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
    );

    const cmd =
      `CRTSRCPF FILE(${toLib}/${srcFile}) ` +
      `RCDLEN(112)`;

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log("COPY SRC SQL");
    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${srcFile} created in ${toLib}`
    });

  } catch (err) {

    console.dir(err, { depth: null });

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// COPY MEMBER
//
app.post("/copy-member", async (req, res) => {

 const {
  fromLib,
  srcFile,
  member,
  toLib
} = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
    );

    const cmd =
      `CPYSRCF ` +
      `FROMFILE(${fromLib}/${srcFile}) ` +
      `TOFILE(${toLib}/${srcFile}) ` +
      `FROMMBR(${member}) ` +
      `TOMBR(${member}) ` +
      `MBROPT(*REPLACE)`;

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log("COPY MEMBER SQL");
    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${member} copied to ${toLib}`
    });

  } catch (err) {

    console.dir(err, { depth: null });

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

  const {
    targetlib,
    srclib,
    srcfile,
    member
  } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
    );

    const cmd =
      `CRTBNDRPG ` +
      `PGM(${targetlib}/${member}) ` +
      `SRCFILE(${srclib}/${srcfile}) ` +
      `SRCMBR(${member})`;

const compileLibs =
  process.env.COMPILE_LIBL.split(",");

for (const lib of compileLibs) {

  await connection.query(`
CALL QSYS2.QCMDEXC('ADDLIBLE LIB(${lib})')
`);

}

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log("COMPILE RPG SQL");
    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${member} compiled`
    });

  } catch (err) {

    console.dir(err, { depth: null });

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// COMPILE SQL RPG
//
app.post("/compile-sqlrpg", async (req, res) => {

  const {
    targetlib,
    srclib,
    srcfile,
    member
  } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
    );

    const cmd =
      `CRTSQLRPGI ` +
      `OBJ(${targetlib}/${member}) ` +
      `SRCFILE(${srclib}/${srcfile}) ` +
      `SRCMBR(${member})`;

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log("COMPILE SQL RPG");
    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${member} compiled`
    });

  } catch (err) {

    console.dir(err, { depth: null });

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// COMPILE PF
//
app.post("/compile-pf", async (req, res) => {

  const {
    targetlib,
    srclib,
    srcfile,
    member
  } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
    );

    const cmd =
      `CRTPF ` +
      `FILE(${targetlib}/${member}) ` +
      `SRCFILE(${srclib}/${srcfile}) ` +
      `SRCMBR(${member})`;

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log("COMPILE PF SQL");
    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${member} created`
    });

  } catch (err) {

    console.dir(err, { depth: null });

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});



//
// CALL PROGRAM
//
app.post("/call-pgm", async (req, res) => {

  const {
    library,
    program
  } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};System=${process.env.IBMI_HOST};UID=${process.env.IBMI_USER};PWD=${process.env.IBMI_PASSWORD};CCSID=1208;NAM=1;`
    );

    const cmd =
      `CALL PGM(${library}/${program})`;

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log("CALL PROGRAM SQL");
    console.log(sql);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${program} called`
    });

  } catch (err) {

    console.dir(err, { depth: null });

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// DEPLOY OBJECT
//
app.post("/deploy-obj", async (req, res) => {

  console.log("DEPLOY ARRIVED");
  console.log(req.body);

  const {
    object,
    type,
    fromLib,
    toLib
  } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};
       System=${process.env.IBMI_HOST};
       UID=${process.env.IBMI_USER};
       PWD=${process.env.IBMI_PASSWORD};
       CCSID=1208;
       NAM=1;`
    );

//
// DELETE OLD OBJECT
//

const deleteCmd =
  `DLTOBJ OBJ(${toLib}/${object}) ` +
  `OBJTYPE(${type})`;

console.log("DELETE CMD");
console.log(deleteCmd);

try {

  await connection.query(
    `CALL QSYS2.QCMDEXC('${deleteCmd}')`
  );

  console.log("OLD OBJECT DELETED");

} catch (e) {

  console.log("OLD OBJECT NOT FOUND");

}
//
// COPY NEW OBJECT
//

const copyCmd =
  `CRTDUPOBJ OBJ(${object}) ` +
  `FROMLIB(${fromLib}) ` +
  `OBJTYPE(${type}) ` +
  `TOLIB(${toLib})`;

console.log("COPY CMD");
console.log(copyCmd);

await connection.query(
  `CALL QSYS2.QCMDEXC('${copyCmd}')`
);


    await connection.close();

    res.json({
      success: true,
      message: `${object} deployed`
    });

  } catch (err) {

    console.log("DEPLOY ERROR");

    console.dir(err, { depth: null });

    console.log(err.message);

    if (err.odbcErrors) {
      console.dir(err.odbcErrors, { depth: null });
    }

    res.status(500).json({
      success: false,
      error: err.message
    });

  }

});

//
// DEPLOY MEMBER
//


app.post("/deploy-member", async (req, res) => {

  const {
    fromLib,
    srcFile,
    member,
    toLib
  } = req.body;

  try {

    const connection = await odbc.connect(
      `Driver={IBM i Access ODBC Driver};
       System=${process.env.IBMI_HOST};
       UID=${process.env.IBMI_USER};
       PWD=${process.env.IBMI_PASSWORD};
       CCSID=1208;
       NAM=1;`
    );

    const cmd =
  `CPYSRCF FROMFILE(${fromLib}/${srcFile}) ` +
  `TOFILE(${toLib}/${srcFile}) ` +
  `FROMMBR(${member}) ` +
  `TOMBR(${member}) ` +
  `MBROPT(*REPLACE)`;

    const sql = `
CALL QSYS2.QCMDEXC('${cmd}')
`;

    console.log(cmd);

    await connection.query(sql);

    await connection.close();

    res.json({
      success: true,
      message: `${member} deployed`
    });

  } catch (err) {

    console.dir(err, { depth: null });

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

});
