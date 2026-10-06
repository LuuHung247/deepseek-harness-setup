module.exports = {
  apps: [
    {
      name: "dsh-web",
      // Call node.exe directly: pm2 running bin.js itself reports "online" but dsh never starts.
      script: process.execPath,
      args: [
        process.env.APPDATA + "\\npm\\node_modules\\@deepseek-ai\\dsh\\lib\\bin.js",
        "web",
        "--no-open",
        "--port",
        "47831",
      ],
      interpreter: "none",
      cwd: process.env.USERPROFILE + "\\dsh-test",
      autorestart: true,
      max_restarts: 10,
      windowsHide: true,
    },
  ],
};
